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
  SetUsernameDto,
  UpdateUserDataDto,
  UserDto,
  BanUserDto,
} from './user.dto';
import { UserService } from './user.service';
import { readFileSync } from 'fs';
import { OrganizationService } from '../organization/organization.service';

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
    private orgService: OrganizationService,
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

      await Promise.all(
        users.map(
          async (curUser: User) =>
            await this.userService.emitUpdateUserData(
              user,
              curUser,
              false,
              false,
            ),
        ),
      );
    }
  }
  @SubscribeMessage('requestUserData')
  async requestUserData(
    @CallingUser() user: User,
    @MessageBody() data: RequestUserDataDto,
  ) {
    if (data.userId) {
      const queried = await this.userService.byId(data.userId);

      if (queried) {
        await this.userService.emitUpdateUserData(user, queried, false, true);
      }
    } else {
      await this.userService.emitUpdateUserData(user, user, false, true);
    }
  }

  @SubscribeMessage('updateUserData')
  async updateUserData(
    @CallingUser() user: User,
    @MessageBody() data: UpdateUserDataDto,
  ) {
    if (data.deleted) {
      const user = await this.userService.byId(data.user as string);
      if (user) {
        await this.userService.deleteUser(user);
        await this.userService.emitUpdateUserData(user, user, true, true);
      }
    } else {
      const updatedUser = await this.userService.updateUser(
        user,
        data.user as UserDto,
      );

      await this.userService.emitUpdateUserData(null, updatedUser, false, true);
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
    await this.userService.emitUpdateUserData(user, user, false, true);
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

    await this.userService.emitUpdateUserData(null, false, true, true);

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

  @SubscribeMessage('addManager')
  async addManager(
    @CallingUser() user: User,
    @MessageBody() data: { email: string; organizationId: string },
  ) {
    if (!user.administrator) return;

    await this.orgService.addManager(user, data.email, data.organizationId);

    const org = await this.orgService.getOrganizationById(data.organizationId);
    await this.orgService.emitUpdateOrganizationData(org, false);

    const manager = await this.userService.byEmail(data.email);
    await this.userService.emitUpdateUserData(
      manager,
      false,
      false,
      true,
      user,
    );
  }

  @SubscribeMessage('joinOrganization')
  async joinOrganization(
    @CallingUser() user: User,
    @MessageBody() data: { accessCode: string },
  ) {
    await this.orgService.joinOrganization(user, data.accessCode);

    const org = await this.orgService.getOrganizationByCode(data.accessCode);
    await this.orgService.emitUpdateOrganizationData(org, false);

    await this.userService.emitUpdateUserData(user, false, false, true);
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
