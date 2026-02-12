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
  PrevChallenge,
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
import { join } from 'path';
import { AchievementService } from '../achievement/achievement.service';

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
    private achievementService: AchievementService,
  ) { }

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
    username: string | undefined,
    year: string,
    college: string,
    major: string,
    interests: Array<string>,
    lat: number,
    long: number,
    authType: AuthType,
    authToken: string,
    enrollmentType: EnrollmentType,
  ) {
    if (authType === AuthType.DEVICE) {
      const count = await this.prisma.user.count();
      username = 'guest' + (count + 921);
    }

    const allOrg = await this.orgService.getDefaultOrganization(
      OrganizationSpecialUsage.DEVICE_LOGIN,
    );

    const group: Group = await this.groupsService.createFromEvent(
      await this.orgService.getDefaultEvent(allOrg),
    );

    const user: User = await this.prisma.user.create({
      data: {
        score: 0,
        group: { connect: { id: group.id } },
        hostOf: { connect: { id: group.id } },
        memberOf: { connect: { id: allOrg.id } },
        username: username ?? email?.split('@')[0],
        year,
        college,
        major,
        interests,
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
        hasCompletedOnboarding: false,
      },
    });

    await this.eventsService.createDefaultEventTracker(user, lat, long);
    console.log(`User ${user.id} created with username ${username}!`);
    await this.log.logEvent(SessionLogEvent.CREATE_USER, user.id, user.id);

    if (authType === AuthType.GOOGLE) {
      const cornellOrg = await this.orgService.getDefaultOrganization(
        OrganizationSpecialUsage.CORNELL_LOGIN,
      );

      await this.orgService.joinOrganization(user, cornellOrg.accessCode);
    }

    await this.achievementService.createAchievementTrackers(user);

    // Seed default bear items into inventory & equipped loadout
    const defaultBearItems = await this.prisma.bearItem.findMany({
      where: { isDefault: true },
    });

    for (const item of defaultBearItems) {
      await this.prisma.userBearInventory.create({
        data: { userId: user.id, bearItemId: item.id },
      });
      await this.prisma.userBearEquipped.create({
        data: { userId: user.id, bearItemId: item.id, slot: item.slot },
      });
    }

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

  /**
   * Delete a user based on their user id.
   * @param user the user who will be deleted.
   */
  async deleteUser(ability: AppAbility, user: User) {
    if (
      (await this.prisma.user.count({
        where: {
          AND: [{ id: user.id }, accessibleBy(ability, Action.Delete).User],
        },
      })) < 1
    ) {
      return;
    }

    await this.log.logEvent(SessionLogEvent.DELETE_USER, user.id, user.id);
    await this.prisma.user.delete({ where: { id: user.id } });
    await this.prisma.$transaction(async tx => {
      await this.groupsService.fixOrDeleteGroup({ id: user.groupId }, tx);
    });
    console.log(`User ${user.id} deleted!`);
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
   * Marks a user as having completed onboarding
   * @param user the user which has completed onboarding
   * @returns A promise containing the updated user
   */
  async completeOnboarding(user: User): Promise<User> {
    return await this.prisma.user.update({
      where: { id: user.id },
      data: { hasCompletedOnboarding: true },
    });
  }

  /**
   * Resets a user's completed onboarding status to false
   * @param user the user who's onboarding is being reset
   * @returns A promise containing the updated user
   */
  async resetOnboarding(user: User): Promise<User> {
    return await this.prisma.user.update({
      where: { id: user.id },
      data: { hasCompletedOnboarding: false },
    });
  }

  /**
   * Update a User's username, email, college, major, or year.
   * @param user User requiring an update.
   * @returns The new user after the update is made
   */
  async updateUser(ability: AppAbility, user: UserDto): Promise<User> {
    const username = user.username
      ? new CensorSensor()
        .cleanProfanityIsh(
          user.username
            ?.substring(0, 128)
            ?.replaceAll(/[^_A-Za-z0-9]/g, ' ')
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
      userObj.id,
      {
        username: username,
        email: user.email,
        college: user.college,
        major: user.major,
        year: user.year,
      },
      'User',
      ability,
      Action.Update,
      this.prisma.user,
    );

    return await this.prisma.user.update({
      where: { id: userObj.id },
      data: assignData,
    });
  }

  /**
   * Check if a user exists based on their authentication type and id.
   * @param authType the authentication type of the user.
   * @param id the id of the user.
   * @returns A promise containing the user if they exist.
   *         Otherwise, it returns null.
   */
  async checkIfUserExists(
    authType: AuthType,
    id: string,
  ): Promise<User | null> {
    return this.byAuth(authType, id);
  }

  async dtoForUserData(user: User, partial: boolean): Promise<UserDto> {
    const joinedUser = await this.prisma.user.findUniqueOrThrow({
      where: { id: user.id },
      include: {
        eventTrackers: true,
        favorites: true,
        group: { select: { friendlyId: true } },
        completedChallenges: true,
      },
    });

    return {
      id: joinedUser.id,
      username: joinedUser.username,
      enrollmentType: joinedUser.enrollmentType,
      email: joinedUser.email,
      college: joinedUser.college,
      major: joinedUser.major,
      year: joinedUser.year,
      score: joinedUser.score,
      coins: joinedUser.coins,
      groupId: joinedUser.group.friendlyId,
      hasCompletedOnboarding: joinedUser.hasCompletedOnboarding,
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
      target ?? user.id,
      dto,
      {
        id: user.id,
        subject: 'User',
        dtoField: 'user',
        prismaStore: this.prisma.user,
      },
    );
  }
}
