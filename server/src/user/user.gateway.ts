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
import { AchievementService } from '../achievement/achievement.service';

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
    private achievementService: AchievementService,
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
    let users: User[] = [];
    if (!user.administrator) {
      users = [user];
    } else {
      users = await this.userService.getAllUserData();
    }

    await Promise.all(
      users.map(
        async (us: User) =>
          await this.userService.emitUpdateUserData(us, false, false, user),
      ),
    );

    return users.length;
  }

  @SubscribeMessage('requestUserData')
  async requestUserData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: RequestUserDataDto,
  ) {
    if (data.userId) {
      const queried = await this.userService.byId(data.userId);
      if (queried) {
        await this.userService.emitUpdateUserData(queried, false, false, user);
      } else {
        await this.clientService.emitErrorData(
          user,
          'Error requesting user by id',
        );
        return false;
      }
    } else {
      await this.userService.emitUpdateUserData(user, false, false, user);
    }

    return true;
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
    return true;
  }

  @SubscribeMessage('setAuthToDevice')
  async setAuthToDevice(
    @CallingUser() user: User,
    @MessageBody() data: SetAuthToDeviceDto,
  ) {
    await this.userService.setAuthType(user, AuthType.DEVICE, data.deviceId);
    return true;
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
    return true;
  }

  @SubscribeMessage('banUser')
  async banUser(@CallingUser() user: User, @MessageBody() data: BanUserDto) {
    if (user.administrator) {
      const user = await this.userService.byId(data.userId);
      if (user) {
        const us = await this.userService.banUser(user, data.isBanned);
        await this.userService.emitUpdateUserData(us, false, false);
        return true;
      }
    }
    return false;
  }

  @SubscribeMessage('addManager')
  async addManager(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: AddManagerDto,
  ) {
    const org = await this.orgService.getOrganizationById(data.organizationId);

    if (
      !org ||
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
    return manager.id;
  }

  @SubscribeMessage('joinOrganization')
  async joinOrganization(
    @CallingUser() user: User,
    @MessageBody() data: JoinOrganizationDto,
  ) {
    const success = await this.orgService.joinOrganization(
      user,
      data.accessCode,
    );

    if (!success) return false;

    await this.achievementService.createAchievementTrackers(user);

    const org = await this.orgService.getOrganizationByCode(data.accessCode);
    await this.orgService.emitUpdateOrganizationData(org, false);

    await this.userService.emitUpdateUserData(user, false, false);

    return true;
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
    return true;
  }
}
