import { SessionLogService } from './../session-log/session-log.service';
import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { EventService } from '../event/event.service';
import { GroupService } from '../group/group.service';
import { v4 } from 'uuid';
import {
  AuthType,
  Group,
  PrismaClient,
  SessionLogEvent,
  User,
} from '@prisma/client';
import {
  UpdateUserDataAuthTypeDto,
  UpdateUserDataDto,
} from '../client/update-user-data.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UserService {
  constructor(
    private log: SessionLogService,
    private prisma: PrismaService,
    @Inject(forwardRef(() => EventService))
    private eventsService: EventService,
    private groupsService: GroupService,
  ) {}

  /** Find a user by their authentication token */
  async byAuth(authType: AuthType, authToken: string) {
    return await this.prisma.user.findFirst({ where: { authType, authToken } });
  }

  /** Registers a user using a certain authentication scheme */
  async register(
    email: string,
    username: string,
    lat: number,
    long: number,
    authType: AuthType,
    authToken: string,
  ) {
    const defEv = await this.eventsService.getDefaultEvent();
    const group: Group = await this.groupsService.createFromEvent(defEv);
    const user: User = await this.prisma.user.create({
      data: {
        score: 0,
        group: { connect: { id: group.id } },
        hostOf: { connect: { id: group.id } },
        username,
        email,
        authToken,
        authType,
        hashedRefreshToken: '',
        superuser: email === process.env.SUPERUSER,
        adminGranted:
          email === process.env.SUPERUSER || process.env.DEVELOPMENT === 'true',
        adminRequested: false,
        isRanked: true,
      },
    });

    await this.eventsService.createDefaultEventTracker(user, lat, long);

    await this.log.logEvent(SessionLogEvent.CREATE_USER, user.id, user.id);

    return user;
  }

  /** Get the top N users by score */
  async getTopPlayers(firstIndex: number, count: number) {
    return await this.prisma.user.findMany({
      where: { isRanked: true },
      orderBy: { score: 'desc' },
      skip: firstIndex,
      take: count,
    });
  }

  async byId(id: string) {
    return await this.prisma.user.findUnique({ where: { id } });
  }

  async deleteUser(user: User) {
    await this.log.logEvent(SessionLogEvent.DELETE_USER, user.id, user.id);
    await this.prisma.user.delete({ where: { id: user.id } });
    await this.groupsService.fixOrDeleteGroup({ id: user.groupId });
  }

  async dtoForUserData(user: User): Promise<UpdateUserDataDto> {
    const joinedUser = await this.prisma.user.findUniqueOrThrow({
      where: { id: user.id },
      include: {
        rewards: true,
        eventTrackers: true,
        group: { select: { friendlyId: true } },
      },
    });

    return {
      id: joinedUser.id,
      username: joinedUser.username,
      score: joinedUser.score,
      groupId: joinedUser.group.friendlyId,
      authType: (
        joinedUser.authType as string
      ).toLowerCase() as UpdateUserDataAuthTypeDto,
      rewardIds: joinedUser.rewards.map(rw => rw.id),
      trackedEventIds: joinedUser.eventTrackers.map(ev => ev.eventId),
      ignoreIdLists: false,
    };
  }

  async setUsername(user: User, username: string) {
    const restriction = await this.prisma.restrictionGroup.findUnique({
      where: { id: user.restrictedById ?? '' },
    });

    if (!restriction?.canEditUsername) {
      return false;
    }

    await this.log.logEvent(SessionLogEvent.EDIT_USERNAME, user.id, user.id);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { username },
    });
  }
}
