import { Injectable } from '@nestjs/common';
import {
  Challenge,
  DifficultyMode,
  EventBase,
  TimeLimitationType,
  EventTracker,
  User,
} from '@prisma/client';
import { LeaderDto, UpdateLeaderDataDto } from '../challenge/challenge.dto';
import { v4 } from 'uuid';
import { ClientService } from '../client/client.service';
import {
  defaultChallengeData,
  defaultEventData,
  OrganizationService,
} from '../organization/organization.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  EventDto,
  EventTrackerDto,
  UpdateEventDataDto,
  RequestRecommendedEventsDto,
} from './event.dto';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { accessibleBy } from '@casl/prisma';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';

@Injectable()
export class EventService {
  constructor(
    private clientService: ClientService,
    private orgService: OrganizationService,
    private readonly prisma: PrismaService,
    private abilityFactory: CaslAbilityFactory,
  ) {}

  /** Get event by id */
  async getEventById(id: string | null) {
    if (!id) throw 'Found null event id! Possible null linked event.';
    return await this.prisma.eventBase.findUnique({ where: { id } });
  }

  /** Get events by ids */
  async getEventsByIdsForAbility(
    ability: AppAbility,
    ids?: string[],
  ): Promise<EventBase[]> {
    return await this.prisma.eventBase.findMany({
      where: {
        AND: [{ id: { in: ids } }, accessibleBy(ability).EventBase],
      },
    });
  }

  /** Get top players for event */
  async getTopTrackersForEvent(eventId: string, offset: number, count: number) {
    return await this.prisma.eventTracker.findMany({
      where: {
        eventId: eventId,
        isRankedForEvent: true,
        user: {
          isRanked: true,
          isBanned: false,
        },
      },
      skip: offset,
      take: count,
      orderBy: { score: 'desc' },
      include: {
        user: {
          select: { id: true, username: true },
        },
      },
    });
  }

  /** Verifies that a challenge is in an event */
  async isChallengeInEvent(challengeId: string, eventId: string) {
    return (
      (await this.prisma.eventBase.count({
        where: {
          id: eventId,
          challenges: {
            some: {
              id: challengeId,
            },
          },
        },
      })) > 0
    );
  }

  /** Creates an event tracker with the closest challenge as the current one */
  async createDefaultEventTracker(user: User, lat: number, long: number) {
    // gets default event of user's first organization
    // we let users choose which org they want the default event for
    const defEv = await this.orgService.getDefaultEvent(
      (
        await this.prisma.user.findUniqueOrThrow({
          where: { id: user.id },
          include: { memberOf: true },
        })
      ).memberOf[0],
    );

    lat = +lat;
    long = +long;

    const defaultEvent: Challenge[] = await this.prisma.$queryRaw`
      select * from "EventBase" ev 
      inner join "Challenge" chal 
      on ev.id = chal."linkedEventId" and ev."id" = ${defEv.id}
      order by ((chal."latitude" - ${lat})^2 + (chal."longitude" - ${long})^2) desc
    `;

    if (defaultEvent.length === 0) throw 'Cannot find closest challenge!';

    const closestChalId = defaultEvent[0].id;
    const defaultEvId = defaultEvent[0].linkedEventId!;

    const progress = await this.prisma.eventTracker.create({
      data: {
        score: 0,
        isRankedForEvent: true,
        event: { connect: { id: defaultEvId } },
        curChallenge: { connect: { id: closestChalId } },
        user: { connect: { id: user.id } },
      },
    });

    return progress;
  }

  /**
   *
   * @param user calling User
   * @param event event to create Tracker for
   * @returns the created eventTracker
   */
  async createEventTracker(user: User, event: EventBase) {
    const existing = await this.prisma.eventTracker.findFirst({
      where: { userId: user.id, eventId: event.id },
    });

    if (existing) {
      return existing;
    }

    const closestChallenge = await this.prisma.challenge.findFirstOrThrow({
      where: {
        eventIndex: 0,
        linkedEvent: { id: event.id },
      },
    });

    const progress = await this.prisma.eventTracker.create({
      data: {
        score: 0,
        isRankedForEvent: true,
        eventId: event.id,
        curChallengeId: closestChallenge.id,
        userId: user.id,
      },
    });

    return progress;
  }

  /** Get a player's event trackers by event id */
  async getEventTrackersByEventId(user: User, events: string[]) {
    return await this.prisma.eventTracker.findMany({
      where: {
        userId: user.id,
        eventId: { in: events },
      },
      include: {
        completedChallenges: {
          include: {
            challenge: {
              select: { id: true },
            },
          },
        },
      },
    });
  }

  /** Gets a player's event tracker based on group */
  async getCurrentEventTrackerForUser(user: User) {
    const evTracker = await this.prisma.eventTracker.findFirst({
      where: {
        id: user.id,
        event: {
          activeGroups: { some: { id: user.groupId } },
        },
      },
      include: { event: true },
    });

    if (!evTracker) {
      const ev = await this.prisma.eventBase.findFirstOrThrow({
        where: {
          activeGroups: { some: { id: user.groupId } },
        },
      });
      return await this.createEventTracker(user, ev);
    }
    return evTracker;
  }

  async getRecommendedEventsForUser(
    user: User,
    data: RequestRecommendedEventsDto,
  ) {
    const evs: EventBase[] = await this.prisma.$queryRaw`
      select * from "EventBase" ev 
      where ev."id" in (select e."A" from "_eventOrgs" e inner join "_player" p on e."B" = p."A" and ${
        user.id
      } = p."B")
      order by ((ev."latitude" - ${data.latitude})^2 + (ev."longitude" - ${
      data.longitude
    })^2)
      fetch first ${data.count ?? 4} rows only
    `;
    return evs;
  }

  /** Get the top N users by score */
  async getTopPlayers(firstIndex: number, count: number) {
    return await this.prisma.user.findMany({
      where: { isRanked: true, isBanned: false },
      orderBy: { score: 'desc' },
      skip: firstIndex,
      take: count,
    });
  }

  async dtoForEvent(ev: EventBase): Promise<EventDto> {
    const chals = await this.prisma.challenge.findMany({
      where: { linkedEventId: ev.id },
      select: { id: true, eventIndex: true, latitude: true, longitude: true },
    });

    const sortedChals = chals.sort((a, b) => a.eventIndex - b.eventIndex);

    return {
      id: ev.id,
      name: ev.name,
      description: ev.description,
      timeLimitation:
        ev.timeLimitation == TimeLimitationType.LIMITED_TIME
          ? 'LIMITED_TIME'
          : 'PERPETUAL',
      endTime: ev.endTime.toUTCString(),
      requiredMembers: ev.requiredMembers,
      indexable: ev.indexable,
      challenges: sortedChals.map(c => c.id),
      difficulty:
        ev.difficulty === DifficultyMode.EASY
          ? 'Easy'
          : ev.difficulty === DifficultyMode.NORMAL
          ? 'Normal'
          : 'Hard',
      latitude: ev.latitude,
      longitude: ev.longitude,
    };
  }

  async dtoForEventTracker(tracker: EventTracker): Promise<EventTrackerDto> {
    const completedChallenges = await this.prisma.challenge.findMany({
      where: { completions: { some: { userId: tracker.userId } } },
      include: { completions: { where: { userId: tracker.userId } } },
    });

    return {
      eventId: tracker.eventId,
      isRanked: tracker.isRankedForEvent,
      curChallengeId: tracker.curChallengeId,
      prevChallenges: completedChallenges.map(pc => pc.id),
      prevChallengeDates: completedChallenges.map(pc =>
        pc.completions[0].timestamp.toUTCString(),
      ),
    };
  }

  async emitUpdateEventTracker(tracker: EventTracker, target?: User) {
    const dto = await this.dtoForEventTracker(tracker);
    await this.clientService.sendProtected(
      'updateEventTrackerData',
      target?.id ?? tracker.id,
      dto,
      'EventTracker',
    );
  }

  async emitUpdateEventData(ev: EventBase, deleted: boolean, target?: User) {
    const dto: UpdateEventDataDto = {
      event: deleted ? { id: ev.id } : await this.dtoForEvent(ev),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateEventData',
      target?.id ?? ev.id,
      dto,
      subject('EventBase', ev),
    );
  }

  async emitUpdateLeaderData(
    offset: number,
    count: number,
    event: EventBase | null,
    target: User,
  ) {
    if (
      event &&
      this.abilityFactory
        .createForUser(target)
        .cannot(Action.Read, subject('EventBase', event))
    ) {
      await this.clientService.emitErrorData(
        target,
        'Cannot read leader data for inaccessible event!',
      );
      return;
    }

    let leaderData: LeaderDto[] = [];
    if (event) {
      const trackers = await this.getTopTrackersForEvent(
        event.id,
        offset,
        count,
      );

      leaderData = trackers.map(tracker => ({
        userId: tracker.id,
        username: tracker.user.username,
        score: tracker.score,
      }));
    } else {
      const players = await this.getTopPlayers(offset, count);

      leaderData = players.map(p => ({
        userId: p.id,
        username: p.username,
        score: p.score,
      }));
    }

    const dto: UpdateLeaderDataDto = {
      eventId: event?.id ?? '',
      offset,
      users: leaderData,
    };

    await this.clientService.sendProtected('updateLeaderData', target.id, dto);
  }

  async upsertEventFromDto(ability: AppAbility, event: EventDto) {
    let ev = await this.prisma.eventBase.findFirst({ where: { id: event.id } });

    const assignData = {
      requiredMembers: event.requiredMembers,
      name: event.name?.substring(0, 2048),
      description: event.description?.substring(0, 2048),
      timeLimitation:
        event.timeLimitation === 'LIMITED_TIME'
          ? TimeLimitationType.LIMITED_TIME
          : TimeLimitationType.PERPETUAL,
      endTime: event.endTime && new Date(event.endTime),
      userFavorites: event.userFavorites,
      indexable: event.indexable,
      difficulty:
        event.difficulty === 'Easy'
          ? DifficultyMode.EASY
          : event.difficulty === 'Normal'
          ? DifficultyMode.NORMAL
          : DifficultyMode.HARD,
      latitude: event.latitude,
      longitude: event.longitude,
    };

    if (
      ev &&
      (await this.prisma.eventBase.findFirst({
        select: {},
        where: {
          AND: [accessibleBy(ability, Action.Update).EventBase, { id: ev.id }],
        },
      }))
    ) {
      const updateData = await this.abilityFactory.filterInaccessible(
        assignData,
        subject('EventBase', ev),
        ability,
        Action.Update,
      );

      ev = await this.prisma.eventBase.update({
        where: { id: ev.id },
        data: updateData,
      });
    } else if (!ev && ability.can(Action.Create, 'Challenge')) {
      const data = {
        requiredMembers:
          assignData.requiredMembers ?? defaultEventData.requiredMembers,
        name: assignData.name?.substring(0, 2048) ?? defaultEventData.name,
        description:
          assignData.description?.substring(0, 2048) ??
          defaultEventData.description,
        timeLimitation: assignData.timeLimitation,
        endTime: assignData.endTime ?? defaultEventData.endTime,
        indexable: assignData.indexable ?? defaultEventData.indexable,
        difficulty: assignData.difficulty ?? defaultEventData.difficulty,
        latitude: assignData.latitude ?? defaultEventData.latitude,
        longitude: assignData.longitude ?? defaultEventData.longitude,
        usedIn: {
          connect: { id: event.initialOrganizationId ?? '' },
        },
      };

      ev = await this.prisma.eventBase.create({
        data,
      });
    }

    if (event?.challenges) {
      let index = 0;
      for (const id of event.challenges) {
        await this.prisma.challenge.update({
          where: { id },
          data: {
            eventIndex: index,
          },
        });

        ++index;
      }
    }

    return ev;
  }

  async removeEvent(eventId: string, ability: AppAbility) {
    return await this.prisma.eventBase.deleteMany({
      where: {
        AND: [
          {
            id: eventId,
          },
          accessibleBy(ability, Action.Delete).EventBase,
        ],
      },
    });
  }
}
