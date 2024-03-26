import { SessionLogService } from './../session-log/session-log.service';
import { forwardRef, Inject, Injectable } from '@nestjs/common';
import {
  AuthType,
  Group,
  SessionLogEvent,
  OrganizationSpecialUsage,
  User,
  EnrollmentType,
  EventBase,
} from '@prisma/client';
import { ClientService } from '../client/client.service';
import { EventService } from '../event/event.service';
import { GroupService } from '../group/group.service';
import { OrganizationService } from '../organization/organization.service';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDataDto, UserAuthTypeDto, UserDto } from './user.dto';
import { CensorSensor } from 'censor-sensor';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';
import { accessibleBy } from '@casl/prisma';

@Injectable()
export class UserService {
  constructor(
    private log: SessionLogService,
    private prisma: PrismaService,
    private eventsService: EventService,
    @Inject(forwardRef(() => GroupService))
    private groupsService: GroupService,
    private orgService: OrganizationService,
    private clientService: ClientService,
    private abilityFactory: CaslAbilityFactory,
  ) {}

  /** Find a user by their authentication token */
  async byAuth(authType: AuthType, authToken: string) {
    return await this.prisma.user.findFirst({ where: { authType, authToken } });
  }

  /** Sets a user's authentication type based on token */
  async setAuthType(user: User, authType: AuthType, token: string) {
    await this.prisma.user.update({
      where: { id: user.id },
      data: { authToken: token, authType: authType },
    });
  }

  /** Registers a user using a certain authentication scheme */
  async register(
    email: string,
    username: string,
    year: string,
    lat: number,
    long: number,
    authType: AuthType,
    authToken: string,
    enrollmentType: EnrollmentType,
  ) {
    if (username == null) username = email?.split('@')[0];
    const defOrg = await this.orgService.getDefaultOrganization(
      authType == AuthType.GOOGLE
        ? OrganizationSpecialUsage.CORNELL_LOGIN
        : OrganizationSpecialUsage.DEVICE_LOGIN,
    );

    const group: Group = await this.groupsService.createFromEvent(
      await this.orgService.getDefaultEvent(defOrg),
    );

    const user: User = await this.prisma.user.create({
      data: {
        score: 0,
        group: { connect: { id: group.id } },
        hostOf: { connect: { id: group.id } },
        memberOf: { connect: { id: defOrg.id } },
        username,
        year,
        email,
        authToken,
        enrollmentType,
        authType,
        hashedRefreshToken: '',
        administrator:
          email === process.env.SUPERUSER ||
          (process.env.DEVELOPMENT === 'true' &&
            !(process.env.TESTING_E2E === 'true')),
        isRanked: true,
      },
    });

    await this.eventsService.createDefaultEventTracker(user, lat, long);
    console.log(`User ${user.id} created!`);
    await this.log.logEvent(SessionLogEvent.CREATE_USER, user.id, user.id);
    return user;
  }

  /**
   *
   * @param id Get user by id
   * @returns The user
   */
  async byId(id: string) {
    return await this.prisma.user.findUnique({ where: { id } });
  }

  /**
   *
   * @param email Get user by email
   * @returns The user
   */
  async byEmail(email: string) {
    return await this.prisma.user.findFirstOrThrow({ where: { email: email } });
  }

  async getAllUserData() {
    return await this.prisma.user.findMany();
  }

  async deleteUser(ability: AppAbility, user: User) {
    if (ability.cannot(Action.Delete, subject('User', user))) {
      return;
    }

    await this.log.logEvent(SessionLogEvent.DELETE_USER, user.id, user.id);
    await this.prisma.user.delete({ where: { id: user.id } });
    await this.prisma.$transaction(async tx => {
      await this.groupsService.fixOrDeleteGroup({ id: user.groupId }, tx);
    });
  }

  /**
   * Ban a user based on their user id.
   * @param user the user who will be banned.
   * @param isBanned a boolean which represents the user's banned status
   * @returns A promise containing the new user if successful.
   */
  async banUser(user: User, isBanned: boolean): Promise<User> {
    return await this.prisma.user.update({
      where: { id: user.id },
      data: {
        isBanned,
      },
    });
  }

  /**
   * Update a User's username, email, or year.
   * @param user User requiring an update.
   * @returns The new user after the update is made
   */
  async updateUser(ability: AppAbility, user: UserDto): Promise<User> {
    const username = user.username
      ? new CensorSensor()
          .cleanProfanityIsh(
            user.username
              ?.substring(0, 128)
              ?.replaceAll(/[^_A-z0-9]/g, ' ')
              ?.replaceAll('_', ' '),
          )
          .replaceAll('*', '_')
          .replaceAll(' ', '_')
      : undefined;

    const userObj = await this.prisma.user.findFirstOrThrow({
      where: {
        AND: [accessibleBy(ability, Action.Update).User, { id: user.id }],
      },
    });

    const assignData = await this.abilityFactory.filterInaccessible(
      {
        username: username,
        email: user.email,
        year: user.year,
      },
      subject('User', userObj),
      ability,
      Action.Update,
    );

    return await this.prisma.user.update({
      where: { id: userObj.id },
      data: assignData,
    });
  }

  async dtoForUserData(user: User, partial: boolean): Promise<UserDto> {
    const joinedUser = await this.prisma.user.findUniqueOrThrow({
      where: { id: user.id },
      include: {
        eventTrackers: true,
        favorites: true,
        group: { select: { friendlyId: true } },
      },
    });

    return {
      id: joinedUser.id,
      username: joinedUser.username,
      enrollmentType: joinedUser.enrollmentType,
      email: joinedUser.email,
      year: joinedUser.year,
      score: joinedUser.score,
      groupId: joinedUser.group.friendlyId,
      isBanned: joinedUser.isBanned,
      authType: (
        joinedUser.authType as string
      ).toLowerCase() as UserAuthTypeDto,
      trackedEvents: partial
        ? undefined
        : joinedUser.eventTrackers.map(ev => ev.eventId),
      favorites: partial
        ? undefined
        : joinedUser.favorites.map((ev: EventBase) => ev.id),
    };
  }

  /**
   *
   * @param user User to emit
   * @param deleted True if user was deleted
   * @param partial True if partial data is updated
   * @param admin True if admin
   * @param client The User requesting the information
   */
  async emitUpdateUserData(
    user: User,
    deleted: boolean,
    partial: boolean,
    target?: User,
  ) {
    const dto: UpdateUserDataDto = {
      user: deleted
        ? { id: user.id }
        : await this.dtoForUserData(user, partial),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateUserData',
      target?.id ?? user.id,
      dto,
      {
        id: user.id,
        subject: subject('User', user),
        dtoField: 'user',
      },
    );
  }
}
