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

@WebSocketGateway({ cors: true })
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
    const groupMember = await user.groupMember?.load();
    const rewards = await user.rewards.loadItems();
    const participatingEvents = await user.participatingEvents.loadItems();
    const group = await groupMember?.group.load();

    this.clientService.emitUpdateUserData(user, {
      id: user.id,
      username: user.username,
      score: user.score,
      groupId: group?.friendlyId ?? 'undefined',
      authType: user.authType as UpdateUserDataAuthTypeDto,
      rewardIds: rewards.map(rw => rw.id),
      trackedEventIds: participatingEvents.map(ev => ev.event.id),
      ignoreIdLists: false,
    });

    return false;
  }

  @SubscribeMessage('setUsername')
  async setUsername(
    @CallingUser() user: User,
    @MessageBody() data: SetUsernameDto,
  ) {
    const groupMember = await user.groupMember?.load();
    const group = await groupMember?.group.load();
    const groupMembers = group?.members;
    const participatingEvents = await user.participatingEvents.loadItems();

    user.username = data.newUsername;

    // Update user that name has changed
    this.clientService.emitUpdateUserData(user, {
      id: user.id,
      username: user.username,
      score: user.score,
      groupId: group?.friendlyId ?? 'undefined',
      authType: user.authType as UpdateUserDataAuthTypeDto,
      rewardIds: [],
      trackedEventIds: [],
      ignoreIdLists: true,
    });

    // Update data for the group
    const updateData: UpdateGroupDataDto = {
      curEventId: group?.currentEvent.id ?? '',
      removeListedMembers: false,
      members: [
        {
          id: user.id,
          name: user.username,
          points: user.score,
          host: groupMember?.isHost ?? false,
          curChallengeId:
            participatingEvents.find(
              ev => ev.event.id === group?.currentEvent.id,
            )?.currentChallenge.id ?? '',
        },
      ],
    };

    // Update groupmates about username change
    for (const member of groupMembers ?? []) {
      this.clientService.emitUpdateGroupData(
        await member?.user.load(),
        updateData,
      );
    }

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
    await this.authService.setAuthType(user, AuthType.NONE, '');
    return false;
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
    return false;
  }
}
