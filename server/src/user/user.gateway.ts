import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { AuthService } from '../auth/auth.service';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { UpdateGroupDataDto } from '../client/update-group-data.dto';
import {
  UpdateUserDataAuthTypeDto,
  UpdateUserDataDto,
} from '../client/update-user-data.dto';
import { CloseAccountDto } from './close-account.dto';
import { RequestUserDataDto } from './request-user-data.dto';
import { SetAuthToDeviceDto } from './set-auth-to-device.dto';
import { SetAuthToOAuthDto } from './set-auth-to-oauth.dto';
import { SetUsernameDto } from './set-username.dto';
import { RequestEventLeaderDataDto } from '../event/request-event-leader-data.dto';
import { RequestGlobalLeaderDataDto } from './request-global-leader-data.dto';
import { UserService } from './user.service';
import { forwardRef, Inject, UseGuards } from '@nestjs/common';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { GroupGateway } from '../group/group.gateway';
import { CensorSensor } from 'censor-sensor';
import { AuthType, User } from '@prisma/client';
import { GroupService } from '../group/group.service';

const replaceAll = require('string.prototype.replaceall');
replaceAll.shim();

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class UserGateway {
  constructor(
    private clientService: ClientService,
    private userService: UserService,
    private groupService: GroupService,
    @Inject(forwardRef(() => AuthService))
    private authService: AuthService,
    private groupGateway: GroupGateway,
  ) {}

  private providerToAuthType(provider: string) {
    let type: AuthType = AuthType.NONE;
    switch (provider) {
      case 'google':
        type = AuthType.GOOGLE;
        break;
      case 'apple':
        type = AuthType.APPLE;
        break;
      case 'device':
        type = AuthType.DEVICE;
        break;
    }
    return type;
  }

  @SubscribeMessage('requestUserData')
  async requestUserData(
    @CallingUser() user: User,
    @MessageBody() data: RequestUserDataDto,
  ) {
    this.clientService.emitUpdateUserData(
      user,
      await this.userService.dtoForUserData(user),
    );

    return false;
  }

  @SubscribeMessage('setUsername')
  async setUsername(
    @CallingUser() user: User,
    @MessageBody() data: SetUsernameDto,
  ) {
    const username = new CensorSensor()
      .cleanProfanityIsh(
        data.newUsername
          .substring(0, 128)
          .replaceAll(/[^_A-z0-9]/g, ' ')
          .replaceAll('_', ' '),
      )
      .replaceAll('*', '_')
      .replaceAll(' ', '_');

    if (!(await this.userService.setUsername(user, username))) {
      return;
    }

    this.clientService.emitInvalidateData({
      userEventData: false,
      userRewardData: false,
      winnerRewardData: false,
      groupData: false,
      challengeData: false,
      leaderboardData: true,
    });

    // Update user that name has changed
    this.clientService.emitUpdateUserData(
      user,
      await this.userService.dtoForUserData(user),
    );

    // Update data for the group
    const members = await this.groupService.getMembers({ id: user.groupId });
    members.forEach(u => this.groupGateway.requestGroupData(u, {}));

    return false;
  }

  @SubscribeMessage('setAuthToDevice')
  async setAuthToDevice(
    @CallingUser() user: User,
    @MessageBody() data: SetAuthToDeviceDto,
  ) {
    await this.authService.setAuthType(user, AuthType.DEVICE, data.deviceId);
    return false;
  }

  @SubscribeMessage('setAuthToOAuth')
  async setAuthToOAuth(
    @CallingUser() user: User,
    @MessageBody() data: SetAuthToOAuthDto,
  ) {
    await this.authService.setAuthType(
      user,
      this.providerToAuthType(data.provider),
      data.authId,
    );
    return false;
  }

  @SubscribeMessage('closeAccount')
  async closeAccount(
    @CallingUser() user: User,
    @MessageBody() data: CloseAccountDto,
  ) {
    await this.authService.setAuthType(user, AuthType.NONE, user.authToken);
    await this.userService.deleteUser(user);

    this.clientService.emitInvalidateData({
      userEventData: true,
      userRewardData: true,
      winnerRewardData: true,
      groupData: true,
      challengeData: true,
      leaderboardData: true,
    });

    return false;
  }

  @SubscribeMessage('requestGlobalLeaderData')
  async requestGlobalLeaderData(
    @CallingUser() user: User,
    @MessageBody() data: RequestGlobalLeaderDataDto,
  ) {
    if (user.restrictedById) return;

    const topPlayers = await this.userService.getTopPlayers(
      data.offset,
      Math.min(data.count, 1024), // Maxed out at 1024 entries
    );

    this.clientService.emitUpdateLeaderData(user, {
      eventId: '',
      offset: data.offset,
      users: topPlayers.map(usr => ({
        userId: usr.id,
        username: usr.username,
        score: usr.score,
      })),
    });
  }
}
