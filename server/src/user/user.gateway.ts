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
  UpdateUserDataDto,
  UserDto,
  BanUserDto,
  AddManagerDto,
  JoinOrganizationDto,
} from './user.dto';
import { UserService } from './user.service';
import { readFileSync } from 'fs';
import { OrganizationService } from '../organization/organization.service';
import { PoliciesGuard } from '../casl/policy.guard';
import { UserAbility } from '../casl/user-ability.decorator';
import { AppAbility } from '../casl/casl-ability.factory';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';

const majors = readFileSync('./src/user/majors.txt', 'utf8').split('\n');

const replaceAll = require('string.prototype.replaceall');
replaceAll.shim();

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
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
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: RequestAllUserDataDto,
  ) {
    if (ability.can(Action.Read, 'User')) {
      const users = await this.userService.getAllUserData();


  for (const ev of users) {
      console.log("Ev is " + (<User>ev).authToken.toString())
    return ev;
  }
      await users.map(
        async (us: User) =>
          await this.userService.emitUpdateUserData(us, false, false, user),
      );
    } else {
      await this.clientService.emitErrorData(
        user,
        'Permission to read all user data denied!',
      );
    }
  }

  @SubscribeMessage('requestUserData')
  async requestUserData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: RequestUserDataDto,
  ) {
    if (data.userId) {
      const queried = await this.userService.byId(data.userId);
      if (queried && ability.can(Action.Read, subject('User', queried))) {
        await this.userService.emitUpdateUserData(queried, false, false, user);
      } else {
        await this.clientService.emitErrorData(
          user,
          'Error requesting user by id',
        );
      }
    } else {
      await this.userService.emitUpdateUserData(user, false, false);
    }
  }

  @SubscribeMessage('updateUserData')
  async updateUserData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: UpdateUserDataDto,
  ) {
    if (data.deleted) {
      const user = await this.userService.byId(data.user.id);
      if (user) {
        await this.userService.deleteUser(ability, user);
        await this.userService.emitUpdateUserData(user, true, true);
      }
    } else {
      const user = await this.userService.updateUser(ability, data.user);
      await this.userService.emitUpdateUserData(user, false, true);
    }
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
        await this.userService.emitUpdateUserData(us, false, false);
      }
    }
  }

  @SubscribeMessage('addManager')
  async addManager(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: AddManagerDto,
  ) {
    const org = await this.orgService.getOrganizationById(data.organizationId);

    if (!ability.can(Action.Manage, subject('Organization', org))) {
      await this.clientService.emitErrorData(
        user,
        'Permission to add manager denied!',
      );
      return;
    }

    if (
      !(await this.orgService.addManager(
        ability,
        data.email,
        data.organizationId,
      ))
    ) {
      await this.clientService.emitErrorData(user, 'Failed to add manager!');
      return;
    }

    const manager = await this.userService.byEmail(data.email);
    await this.clientService.subscribe(manager, org.id);
    await this.orgService.emitUpdateOrganizationData(org, false);
  }

  @SubscribeMessage('joinOrganization')
  async joinOrganization(
    @CallingUser() user: User,
    @MessageBody() data: JoinOrganizationDto,
  ) {
    await this.orgService.joinOrganization(user, data.accessCode);

    const org = await this.orgService.getOrganizationByCode(data.accessCode);
    await this.orgService.emitUpdateOrganizationData(org, false);

    await this.userService.emitUpdateUserData(user, false, false);
  }

  @SubscribeMessage('closeAccount')
  async closeAccount(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: CloseAccountDto,
  ) {
    const group = await this.groupService.getGroupForUser(user);
    await this.userService.setAuthType(user, AuthType.NONE, user.authToken);
    await this.userService.deleteUser(ability, user);
    await this.groupService.emitUpdateGroupData(group, false);
  }
}
