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
import {
  UpdateUserDataDto,
  UserAuthTypeDto,
  UserDto,
  eventFilterDto,
} from './user.dto';
import { CensorSensor } from 'censor-sensor';

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
          email === process.env.SUPERUSER || process.env.DEVELOPMENT === 'true',
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

  async deleteUser(user: User) {
    await this.log.logEvent(SessionLogEvent.DELETE_USER, user.id, user.id);
    await this.prisma.user.delete({ where: { id: user.id } });
    await this.prisma.$transaction(async tx => {
      await this.groupsService.fixOrDeleteGroup({ id: user.groupId }, tx);
    });
  }

  async setUsername(user: User, username: string) {
    await this.prisma.user.update({
      where: { id: user.id },
      data: { username },
    });
  }

  /** Adds event to user's favorite if isFavorite is true, else removes event
   * from favorites if it exists */
  async setFavorite(user: User, ev: EventBase, isFavorite: boolean) {
    if (isFavorite) {
      return await this.prisma.user.update({
        where: { id: user.id },
        data: { favorites: { connect: { id: ev.id } } },
      });
    } else {
      return await this.prisma.user.update({
        where: { id: user.id },
        data: { favorites: { disconnect: { id: ev.id } } },
      });
    }
  }

  /**
   * Filter: new gives all ,
   * with ongoing events listed before not started events.
   * cursorId:
   */

  /**
   * Grabs all events from all of user's allowed events based on the filter.
   * @param user user requesting filtered events
   * @param filter "saved" returns favorited events, "new" returns events that are not started and ongoing, "finished" returns events where each challenge is completed
   * @param cursorId id of the last event in the previous page
   * @returns filtered event id list sorted by ascending id
   */
  async getFilteredEvents(
    user: User,
    filter: eventFilterDto,
    cursorId: string | undefined,
    limit: number,
  ) {
    const joinedUser = await this.prisma.user.findFirstOrThrow({
      where: { id: user.id },
      include: {
        favorites: true,
        memberOf: true,
      },
    });

    let filteredEvents = [{ id: '' }];

    if (filter == 'finished') {
      filteredEvents = await this.prisma.eventBase.findMany({
        select: { id: true },
        orderBy: {
          id: 'asc', // must be ordered to use cursor
        },
        take: limit,
        skip: cursorId ? 1 : 0, // skips the event with id = cursorId
        cursor: cursorId
          ? {
              id: cursorId,
            }
          : undefined,
        where: {
          usedIn: {
            some: { members: { some: { id: user.id } } },
          },
          challenges: {
            every: {
              completions: {
                some: {
                  participants: {
                    some: { id: user.id },
                  },
                },
              },
            },
          },
        },
      });
    } else if (filter == 'new') {
      filteredEvents = await this.prisma.eventBase.findMany({
        select: { id: true },
        orderBy: {
          id: 'asc', // must be ordered to use cursor
        },
        take: limit,
        skip: cursorId ? 1 : 0, // skips the event with id = cursorId
        cursor: cursorId
          ? {
              id: cursorId,
            }
          : undefined,
        where: {
          usedIn: {
            some: { members: { some: { id: user.id } } },
          },
          challenges: {
            some: {
              completions: {
                none: {
                  participants: {
                    some: { id: user.id },
                  },
                },
              },
            },
          },
        },
      });
    } else {
      // filter == 'saved'
      filteredEvents = await this.prisma.eventBase.findMany({
        select: { id: true },
        orderBy: {
          id: 'asc', // must be ordered to use cursor
        },
        take: limit,
        skip: cursorId ? 1 : 0, // skips the event with id = cursorId
        cursor: cursorId
          ? {
              id: cursorId,
            }
          : undefined,
        where: {
          usedIn: {
            some: { members: { some: { id: user.id } } },
          },
          userFavorite: {
            some: { id: user.id },
          },
        },
      });
    }
    return filteredEvents;
  }

  // async setMajor(user: User, major: string) {
  //   await this.prisma.user.update({
  //     where: { id: user.id },
  //     data: { major },
  //   });
  // }
  /**
   * Updates a user's graduation year.
   * @param user user requesting the change in graduation year
   * @param year the new graduation year.
   */
  async setGraduationYear(user: User, year: string) {
    await this.prisma.user.update({
      where: { id: user.id },
      data: { year },
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
  async updateUser(user: UserDto): Promise<User> {
    const username = new CensorSensor()
      .cleanProfanityIsh(
        user.username
          .substring(0, 128)
          .replaceAll(/[^_A-z0-9]/g, ' ')
          .replaceAll('_', ' '),
      )
      .replaceAll('*', '_')
      .replaceAll(' ', '_');

    return await this.prisma.user.update({
      where: { id: user.id },
      data: {
        username: username,
        email: user.email,
        year: user.year,
      },
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
      user: deleted ? user.id : await this.dtoForUserData(user, partial),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateUserData',
      target?.id ?? user.id,
      dto,
      'User',
    );
  }
}
