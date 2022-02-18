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
import { AuthType, User } from '../model/user.entity';
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

@WebSocketGateway()
@UseGuards(UserGuard)
export class UserGateway {
  constructor(
    private clientService: ClientService,
    private userService: UserService,
    @Inject(forwardRef(() => AuthService))
    private authService: AuthService,
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
    const basicUser = await this.userService.loadBasic(user);
    this.clientService.emitUpdateUserData(basicUser, {
      id: user.id,
      username: user.username,
      score: user.score,
      groupId: user.groupMember?.group.id ?? '',
      authType: user.authType as UpdateUserDataAuthTypeDto,
      rewardIds: user.rewards.map(rw => rw.id),
      trackedEventIds: user.participatingEvents.map(ev => ev.event.id),
      ignoreIdLists: false,
    });

    return true;
  }

  @SubscribeMessage('setUsername')
  async setUsername(
    @CallingUser() user: User,
    @MessageBody() data: SetUsernameDto,
  ) {
    const group = await this.userService.loadGroup(user, true);
    const groupMembers = group.members;
    const basicUser = await this.userService.loadBasic(user);
    basicUser.username = data.newUsername;

    // Update user that name has changed
    this.clientService.emitUpdateUserData(basicUser, {
      id: user.id,
      username: user.username,
      score: user.score,
      groupId: user.groupMember?.group.id ?? '',
      authType: user.authType as UpdateUserDataAuthTypeDto,
      rewardIds: [],
      trackedEventIds: [],
      ignoreIdLists: true,
    });

    // Update data for the group
    const updateData: UpdateGroupDataDto = {
      curEventId: group.currentEvent.id,
      update: true,
      members: [
        {
          id: basicUser.id,
          name: basicUser.username,
          points: basicUser.score,
          host: basicUser.groupMember?.isHost ?? false,
          curChallengeId:
            basicUser.participatingEvents.find(
              ev => ev.event.id === group.currentEvent.id,
            )?.currentChallenge.id ?? '',
        },
      ],
    };

    // Update groupmates about username change
    for (const member of groupMembers) {
      this.clientService.emitUpdateGroupData(member.user, updateData);
    }

    return true;
  }

  @SubscribeMessage('setAuthToDevice')
  async setAuthToDevice(
    @CallingUser() user: User,
    @MessageBody() data: SetAuthToDeviceDto,
  ) {
    return this.authService.setAuthType(user, AuthType.DEVICE, data.deviceId);
  }

  @SubscribeMessage('setAuthToOAuth')
  async setAuthToOAuth(
    @CallingUser() user: User,
    @MessageBody() data: SetAuthToOAuthDto,
  ) {
    return this.authService.setAuthType(
      user,
      this.providerToAuthType(data.provider),
      data.authId,
    );
  }

  @SubscribeMessage('closeAccount')
  async closeAccount(
    @CallingUser() user: User,
    @MessageBody() data: CloseAccountDto,
  ) {
    return this.authService.setAuthType(user, AuthType.NONE, '');
  }

  @SubscribeMessage('requestGlobalLeaderData')
  async requestGlobalLeaderData(
    @CallingUser() user: User,
    @MessageBody() data: RequestGlobalLeaderDataDto,
  ) {
    let topPlayers = await this.userService.getTopPlayers(
      data.offset,
      Math.min(data.count, 128), // Maxed out at 128 entries
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

    return true;
  }
}
