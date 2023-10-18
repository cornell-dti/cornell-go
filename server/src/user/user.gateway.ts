import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { AuthType, User } from '@prisma/client';
import { CensorSensor } from 'censor-sensor';
import { UserGuard } from '../auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { GroupGateway } from '../group/group.gateway';
import { GroupService } from '../group/group.service';
import { EventService } from '../event/event.service';
import {
  CloseAccountDto,
  RequestAllUserDataDto,
  RequestGlobalLeaderDataDto,
  RequestUserDataDto,
  RequestFavoriteEventDataDto,
  SetAuthToDeviceDto,
  SetAuthToOAuthDto,
  SetGraduationYearDto,
  SetMajorDto,
  SetUsernameDto,
  RequestFilteredEventDto,
  UpdateUserDataDto,
  UserDto,
  BanUserDto,
} from './user.dto';
import { UserService } from './user.service';
import { readFileSync } from 'fs';

const majors = readFileSync('./src/user/majors.txt', 'utf8').split('\n');

const replaceAll = require('string.prototype.replaceall');
replaceAll.shim();

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class UserGateway {
  constructor(
    private clientService: ClientService,
    private userService: UserService,
    private groupService: GroupService,
    private eventService: EventService,
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

  @SubscribeMessage('requestAllUserData')
  async requestAllUserData(
    @CallingUser() user: User,
    @MessageBody() data: RequestAllUserDataDto,
  ) {
    if (user.administrator) {
      const users = await this.userService.getAllUserData();

      await users.map(
        async (us: User) =>
          await this.userService.emitUpdateUserData(
            us,
            false,
            false,
            true,
            user,
          ),
      );
    }
  }
  @SubscribeMessage('requestUserData')
  async requestUserData(
    @CallingUser() user: User,
    @MessageBody() data: RequestUserDataDto,
  ) {
    if (user.administrator && data.userId) {
      const queried = await this.userService.byId(data.userId);

      if (queried) {
        await this.userService.emitUpdateUserData(
          queried,
          false,
          false,
          true,
          user,
        );
      }
    } else {
      await this.userService.emitUpdateUserData(user, false, false, true, user);
    }
  }

  @SubscribeMessage('updateUserData')
  async updateUserData(
    @CallingUser() user: User,
    @MessageBody() data: UpdateUserDataDto,
  ) {
    if (!user.administrator && user.id !== (data.user as UserDto).id) return;

    if (data.deleted) {
      const user = await this.userService.byId(data.user as string);
      if (user !== null) {
        await this.userService.deleteUser(user);
        await this.userService.emitUpdateUserData(user, true, true);
      }
    } else {
      const user = await this.userService.updateUser(data.user as UserDto);

      await this.userService.emitUpdateUserData(user, false, true);
    }
  }

  @SubscribeMessage('requestFilteredEvents')
  async requestFilteredEvents(
    @CallingUser() user: User,
    @MessageBody() data: RequestFilteredEventDto,
  ) {
    const eventIds = await this.userService.getFilteredEventIds(
      user,
      data.filter,
      data.cursorId,
      data.limit,
    );
    for (const eventId of eventIds) {
      const ev = await this.eventService.getEventById(eventId.id);
      this.clientService.subscribe(user, eventId.id, false);
      await this.eventService.emitUpdateEventData(ev, false, false, user);
    }
  }

  @SubscribeMessage('setFavorite')
  async setFavorite(
    @CallingUser() user: User,
    @MessageBody() data: RequestFavoriteEventDataDto,
  ) {
    const ev = await this.eventService.getEventById(data.eventId);
    await this.userService.setFavorite(user, ev, data.isFavorite);
    await this.userService.emitUpdateUserData(user, false, false, true, user);
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

    await this.userService.setUsername(user, username);

    user.username = username; // Updated so change here too

    await this.userService.emitUpdateUserData(user, false, true, true);

    const group = await this.groupService.getGroupForUser(user);
    await this.groupService.emitUpdateGroupData(group, false);
  }

  // @SubscribeMessage('setMajor')
  // async setMajor(@CallingUser() user: User, @MessageBody() data: SetMajorDto) {
  //   if (majors.includes(data.newMajor)) {
  //     await this.userService.setMajor(user, data.newMajor);

  //     user.major = data.newMajor; // Updated so change here too

  //     await this.userService.emitUpdateUserData(user, false, true, true);
  //   }
  // }

  @SubscribeMessage('setGraduationYear')
  async setGraduationYear(
    @CallingUser() user: User,
    @MessageBody() data: SetGraduationYearDto,
  ) {
    await this.userService.setGraduationYear(user, data.newYear);

    user.year = data.newYear; // Updated so change here too

    await this.userService.emitUpdateUserData(user, false, true, true);
  }

  @SubscribeMessage('setAuthToDevice')
  async setAuthToDevice(
    @CallingUser() user: User,
    @MessageBody() data: SetAuthToDeviceDto,
  ) {
    await this.userService.setAuthType(user, AuthType.DEVICE, data.deviceId);
  }

  @SubscribeMessage('setAuthToOAuth')
  async setAuthToOAuth(
    @CallingUser() user: User,
    @MessageBody() data: SetAuthToOAuthDto,
  ) {
    await this.userService.setAuthType(
      user,
      this.providerToAuthType(data.provider),
      data.authId,
    );
  }

  @SubscribeMessage('banUser')
  async banUser(@CallingUser() user: User, @MessageBody() data: BanUserDto) {
    if (user.administrator) {
      const user = await this.userService.byId(data.userId);
      if (!!user) {
        const us = await this.userService.banUser(user, data.isBanned);

        await this.userService.emitUpdateUserData(us, false, false, true);
      }
    }
  }

  @SubscribeMessage('closeAccount')
  async closeAccount(
    @CallingUser() user: User,
    @MessageBody() data: CloseAccountDto,
  ) {
    const group = await this.groupService.getGroupForUser(user);
    await this.userService.setAuthType(user, AuthType.NONE, user.authToken);
    await this.userService.deleteUser(user);
    await this.groupService.emitUpdateGroupData(group, false);
  }
}
