import { Injectable } from '@nestjs/common';
import {
  Challenge,
  DifficultyMode,
  EventBase,
  TimeLimitationType,
  EventTracker,
  User,
  OrganizationSpecialUsage,
} from '@prisma/client';
import { LeaderDto, UpdateLeaderDataDto } from './event.dto';
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
  UpdateEventTrackerDataDto,
  EventCategoryDto,
  UpdateLeaderPositionDto,
} from './event.dto';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { accessibleBy } from '@casl/prisma';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';

/**
 * Service responsible for managing events and related entities like event trackers.
 *
 * @remarks
 * This service handles operations such as fetching event data, creating and managing
 * event trackers for users, calculating leaderboards, and emitting updates via websockets.
 * It interacts with PrismaService for database operations and uses CASL for authorization checks.
 */
@Injectable()
export class EventService {
  constructor(
    private clientService: ClientService,
    private orgService: OrganizationService,
    private readonly prisma: PrismaService,
    private abilityFactory: CaslAbilityFactory,
  ) {}

  /**
   * Fetches a single event by its unique identifier.
   *
   * @param id - The unique identifier of the event to fetch.
   * @returns A promise that resolves to the EventBase object or null if not found.
   */
  async getEventById(id: string) {
    return await this.prisma.eventBase.findFirst({ where: { id } });
  }

  /**
   * Fetches multiple events by their IDs, respecting CASL abilities.
   *
   * @remarks
   * Filters the events based on the provided ability object to ensure the user
   * only receives events they are permitted to read.
   *
   * @param ability - The CASL ability object defining user permissions.
   * @param ids - An optional array of event IDs to fetch. If omitted, fetches all accessible events.
   * @returns A promise that resolves to an array of accessible EventBase objects.
   */
  async getEventsByIdsForAbility(
    ability: AppAbility,
    ids?: string[],
  ): Promise<EventBase[]> {
    // console.log("Ids are " + ids)
    return await this.prisma.eventBase.findMany({
      where: {
        AND: [
          { id: { in: ids } },
          accessibleBy(ability, Action.Read).EventBase,
        ],
      },
    });
  }

  /**
   * Retrieves the top-ranked event trackers for a specific event.
   *
   * @param eventId - The ID of the event for which to retrieve the leaderboard.
   * @param offset - The number of top trackers to skip (for pagination).
   * @param count - The maximum number of trackers to return.
   * @returns A promise that resolves to an array of event trackers, including user details.
   */
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

  /**
   * Checks if a specific challenge is part of a given event.
   *
   * @param challengeId - The ID of the challenge to check.
   * @param eventId - The ID of the event to check within.
   * @returns A promise that resolves to true if the challenge is in the event, false otherwise.
   */
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

  /**
   * Creates a default event tracker for a user, assigning the geographically closest challenge
   * from the default event of their first organization as the current challenge.
   *
   * @remarks
   * This is typically used when a user logs in or needs an initial tracker state.
   * It calculates the distance based on provided latitude and longitude.
   * Throws an error if the default event has no challenges.
   *
   * @param user - The user for whom to create the tracker.
   * @param lat - The user's current latitude.
   * @param long - The user's current longitude.
   * @returns A promise that resolves to the newly created EventTracker object.
   * @throws If the default event associated with the user's first organization contains no challenges.
   */
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
      order by ((chal."latitude" - ${lat})^2 + (chal."longitude" - ${long})^2) asc
    `;

    if (defaultEvent.length === 0) throw 'Cannot find closest challenge!';

    const closestChalId = defaultEvent[0].id;
    const defaultEvId = defaultEvent[0].linkedEventId!;

    const progress = await this.prisma.eventTracker.create({
      data: {
        score: 0,
        hintsUsed: 0,
        isRankedForEvent: true,
        event: { connect: { id: defaultEvId } },
        curChallenge: { connect: { id: closestChalId } },
        user: { connect: { id: user.id } },
      },
    });

    return progress;
  }

  /**
   * Creates an event tracker for a specific user and event, if one doesn't already exist.
   *
   * @remarks
   * If an tracker already exists for the user and event combination, it returns the existing one.
   * Otherwise, it creates a new tracker and sets the first challenge (by eventIndex) as the current one.
   *
   * @param user - The user for whom to create the tracker.
   * @param event - The event for which to create the tracker.
   * @returns A promise that resolves to the created or existing EventTracker object.
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
        linkedEvent: { id: event.id },
      },
      orderBy: {
        eventIndex: 'asc',
      },
    });

    //Emit timer start event for the first challenge if it has a timer length
    if (closestChallenge.timerLength) {
      await this.clientService.sendEvent(
        [`user/${user.id}`],
        'startTimerForChallenge',
        {
          challengeId: closestChallenge.id,
          timerLength: closestChallenge.timerLength,
        },
      );
    }

    const progress = await this.prisma.eventTracker.create({
      data: {
        score: 0,
        hintsUsed: 0,
        isRankedForEvent: true,
        eventId: event.id,
        curChallengeId: closestChallenge.id,
        userId: user.id,
      },
    });

    //Start timer for the first challenge if it has a timer length
    // if (closestChallenge.timerLength) {
    //   try {
    //     await this.challengeService.startTimer(closestChallenge.id, user.id);
    //   } catch (error) {
    //     console.warn(`Failed to start timer for challenge ${closestChallenge.id}:`, error);
    //   }
    // }

    return progress;
  }

  /**
   * Retrieves all event trackers for a specific user across multiple events.
   *
   * @param user - The user whose trackers are to be fetched.
   * @param events - An array of event IDs to fetch trackers for.
   * @returns A promise that resolves to an array of EventTracker objects, including details about completed challenges.
   */
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

  /**
   * Gets the active event tracker for a user based on their current group.
   *
   * @remarks
   * Finds the event tracker associated with the event that the user's group is currently participating in.
   * If no tracker exists for that event, it creates one.
   *
   * @param user - The user whose current event tracker is needed.
   * @returns A promise that resolves to the user's active EventTracker object (created if necessary).
   */
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

  /**
   * Fetches recommended events for a user based on their location.
   *
   * @remarks
   * Finds events associated with the user's organizations and sorts them by proximity
   * to the specified latitude and longitude.
   *
   * @param user - The user for whom to recommend events.
   * @param data - DTO containing the user's current latitude, longitude, and desired count of recommendations.
   * @returns A promise that resolves to an array of recommended EventBase objects.
   */
  async getRecommendedEventsForUser(
    user: User,
    data: RequestRecommendedEventsDto,
  ) {
    const evs: EventBase[] = await this.prisma.$queryRaw`
      select * from "EventBase" ev 
      where ev."id" in (select e."A" from "_eventOrgs" e inner join "_player" p on e."B" = p."A" and ${
        user.id
      } = p."B")
      order by ((ev."latitude" - ${data.latitudeF})^2 + (ev."longitude" - ${
        data.longitudeF
      })^2)
      fetch first ${data.count ?? 4} rows only
    `;
    return evs;
  }

  /**
   * Retrieves the top N users globally based on their total score.
   *
   * @param firstIndex - The starting index (0-based) for pagination.
   * @param count - The maximum number of users to retrieve.
   * @returns A promise that resolves to an array of top User objects.
   */
  async getTopPlayers(firstIndex: number, count: number) {
    return await this.prisma.user.findMany({
      where: { isRanked: true, isBanned: false },
      orderBy: { score: 'desc' },
      skip: firstIndex,
      take: count,
    });
  }

  /**
   * Converts an EventBase database entity into an EventDto.
   *
   * @remarks
   * Fetches associated challenges and sorts them by their eventIndex before inclusion in the DTO.
   * Formats enum types and dates for the DTO.
   *
   * @param ev - The EventBase object to convert.
   * @returns A promise that resolves to the corresponding EventDto.
   */
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
      longDescription: ev.longDescription,
      category: ev.category as EventCategoryDto,
      timeLimitation:
        ev.timeLimitation === TimeLimitationType.LIMITED_TIME
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
      latitudeF: ev.latitude,
      longitudeF: ev.longitude,
    };
  }

  /**
   * Converts an EventTracker database entity into an EventTrackerDto.
   *
   * @remarks
   * Fetches associated completed challenges (PrevChallenge records) and formats them for the DTO.
   *
   * @param tracker - The EventTracker object to convert.
   * @returns A promise that resolves to the corresponding EventTrackerDto.
   */
  async dtoForEventTracker(tracker: EventTracker): Promise<EventTrackerDto> {
    const prevChallenges = await this.prisma.prevChallenge.findMany({
      where: {
        trackerId: tracker.id,
      },
    });

    return {
      eventId: tracker.eventId,
      isRanked: tracker.isRankedForEvent,
      hintsUsed: tracker.hintsUsed,
      curChallengeId: tracker.curChallengeId ?? undefined,
      prevChallenges: prevChallenges.map(pc => ({
        challengeId: pc.challengeId,
        hintsUsed: pc.hintsUsed,
        extensionsUsed: pc.extensionsUsed ?? 0, // Default to 0 for backwards compatibility
        dateCompleted: pc.timestamp.toUTCString(),
      })),
    };
  }

  /**
   * Emits an update notification for an EventTracker via WebSocket.
   *
   * @remarks
   * Converts the tracker to a DTO and sends it to the specified target user or
   * defaults to the user associated with the tracker. Uses `clientService.sendProtected`
   * for secure, permission-checked emission.
   *
   * @param tracker - The EventTracker that has been updated.
   * @param target - Optional. The specific user to send the update to. Defaults to the tracker's user.
   */
  async emitUpdateEventTracker(tracker: EventTracker, target?: User) {
    const dto = await this.dtoForEventTracker(tracker);
    await this.clientService.sendProtected(
      'updateEventTrackerData',
      target ?? tracker.id,
      dto,
      {
        id: tracker.id,
        subject: 'EventTracker',
        prismaStore: this.prisma.eventTracker,
      },
    );
  }

  /**
   * Increments the hint count for the user's current event tracker.
   *
   * @param user - The user who used a hint.
   * @returns A promise that resolves to the updated EventTracker object.
   */
  async useEventTrackerHint(user: User) {
    var evTracker = await this.getCurrentEventTrackerForUser(user);

    evTracker = await this.prisma.eventTracker.update({
      where: { id: evTracker.id },
      data: { hintsUsed: evTracker.hintsUsed + 1 },
    });
    return evTracker;
  }

  /**
   * Emits an update notification for an EventBase via WebSocket.
   *
   * @remarks
   * Can signify either an update to an existing event or its deletion.
   * Converts the event to a DTO (or just includes the ID if deleted) and sends it
   * to the specified target user or defaults to broadcasting within the event's context.
   * Uses `clientService.sendProtected` for secure, permission-checked emission.
   *
   * @param ev - The EventBase that was updated or deleted.
   * @param deleted - Boolean flag indicating if the event was deleted.
   * @param target - Optional. The specific user to send the update to. Defaults to broadcasting.
   */
  async emitUpdateEventData(ev: EventBase, deleted: boolean, target?: User) {
    const dto: UpdateEventDataDto = {
      event: deleted ? { id: ev.id } : await this.dtoForEvent(ev),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateEventData',
      target ?? ev.id,
      dto,
      {
        id: ev.id,
        subject: 'EventBase',
        dtoField: 'event',
        prismaStore: this.prisma.eventBase,
      },
    );
  }

  /**
   * Emits an update for a player's position on the leaderboard via WebSocket.
   *
   * @remarks
   * Sends the provided DTO containing leaderboard position changes. This is typically
   * used for real-time updates to the leaderboard UI. Uses `clientService.sendProtected`.
   *
   * @param updateDto - The DTO containing the leaderboard position update information.
   */
  async emitUpdateLeaderPosition(updateDto: UpdateLeaderPositionDto) {
    await this.clientService.sendProtected(
      'updateLeaderPosition',
      null,
      updateDto,
    );
  }

  /**
   * Fetches and emits leaderboard data (top players) via WebSocket to a specific user.
   *
   * @remarks
   * Can fetch either the global leaderboard or the leaderboard for a specific event.
   * Performs a permission check before fetching event-specific leaderboards.
   * Sends the data using `clientService.sendProtected`.
   *
   * @param offset - The number of top players/trackers to skip (for pagination).
   * @param count - The maximum number of players/trackers to return.
   * @param event - Optional. The specific event to get the leaderboard for. If null, fetches the global leaderboard.
   * @param target - The user to send the leaderboard data to.
   */
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
      eventId: event?.id,
      offset,
      users: leaderData,
    };

    await this.clientService.sendProtected('updateLeaderData', target, dto);
  }

  /**
   * Creates or updates an event based on the provided DTO and user permissions.
   *
   * @remarks
   * Checks if the user has permission to update the specified organization (if creating)
   * or the event itself (if updating). Filters inaccessible fields based on CASL abilities.
   * Handles challenge reordering and fixes potentially broken event trackers after updates.
   *
   * @param ability - The CASL ability object defining the user's permissions.
   * @param event - The DTO containing the event data for creation or update. Must include `initialOrganizationId` if creating.
   * @returns A promise that resolves to the created or updated EventBase object, or null if permissions are insufficient.
   */
  async upsertEventFromDto(ability: AppAbility, event: EventDto) {
    let ev = await this.prisma.eventBase.findFirst({ where: { id: event.id } });

    const canUpdateOrg =
      (await this.prisma.organization.count({
        where: {
          AND: [
            { id: event.initialOrganizationId ?? '' },
            accessibleBy(ability, Action.Update).Organization,
          ],
        },
      })) > 0;

    const canUpdateEv =
      (await this.prisma.eventBase.count({
        where: {
          AND: [
            accessibleBy(ability, Action.Update).EventBase,
            { id: ev?.id ?? '' },
          ],
        },
      })) > 0;

    const assignData = {
      requiredMembers: event.requiredMembers,
      name: event.name?.substring(0, 2048),
      description: event.description?.substring(0, 2048),
      timeLimitation:
        event.timeLimitation === 'LIMITED_TIME'
          ? TimeLimitationType.LIMITED_TIME
          : TimeLimitationType.PERPETUAL,
      endTime: event.endTime && new Date(event.endTime),
      indexable: event.indexable,
      difficulty:
        event.difficulty &&
        (event.difficulty === 'Easy'
          ? DifficultyMode.EASY
          : event.difficulty === 'Normal'
            ? DifficultyMode.NORMAL
            : DifficultyMode.HARD),
      latitude: event.latitudeF,
      longitude: event.longitudeF,
      category: event.category,
    };

    if (ev && canUpdateEv) {
      const updateData = await this.abilityFactory.filterInaccessible(
        ev.id,
        assignData,
        'EventBase',
        ability,
        Action.Update,
        this.prisma.eventBase,
      );

      ev = await this.prisma.eventBase.update({
        where: { id: ev.id },
        data: updateData,
      });
    } else if (!ev && canUpdateOrg) {
      const data = {
        requiredMembers:
          assignData.requiredMembers ?? defaultEventData.requiredMembers,
        name: assignData.name?.substring(0, 2048) ?? defaultEventData.name,
        description:
          assignData.description?.substring(0, 2048) ??
          defaultEventData.description,
        longDescription:
          event.longDescription?.substring(0, 8192) ??
          defaultEventData.longDescription ??
          '',
        category: assignData.category ?? defaultEventData.category,
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

      console.log(`Created event ${ev.id}`);
    } else {
      return null;
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

    await this.fixEventTrackers(event.id);

    return ev;
  }

  /**
   * Fixes event trackers that might have become inconsistent, e.g., after challenge updates.
   *
   * @remarks
   * Specifically looks for trackers associated with the given eventId that have a null `curChallengeId`.
   * It attempts to find the next appropriate challenge (the earliest uncompleted one by eventIndex)
   * and updates the tracker. Emits an update for each fixed tracker.
   *
   * @param eventId - The ID of the event whose trackers need potential fixing. If null, the function does nothing.
   */
  async fixEventTrackers(eventId?: string) {
    if (!eventId) return;

    const trackers = await this.prisma.eventTracker.findMany({
      where: {
        eventId: eventId,
        curChallengeId: null,
      },
    });

    const newTrackers = await Promise.all(
      trackers.map(async tracker => {
        const nextChal = await this.prisma.challenge.findFirst({
          where: {
            linkedEventId: tracker.eventId,
            completions: { none: { userId: tracker.userId } },
          },
          orderBy: {
            eventIndex: 'asc',
          },
        });

        if (!nextChal) return null;

        return await this.prisma.eventTracker.update({
          where: { id: tracker.id },
          data: { curChallengeId: nextChal?.id },
        });
      }),
    );

    await Promise.all(
      newTrackers.map(tracker => {
        if (tracker) this.emitUpdateEventTracker(tracker);
      }),
    );
  }

  /**
   * Removes an event, ensuring it's not a default event and handling related entities.
   *
   * @remarks
   * Checks user permissions using CASL. Prevents deletion of the default 'DEVICE_LOGIN' event.
   * Updates any groups currently associated with the deleted event to point to the default event.
   * Deletes the event and associated data. Calls `fixEventTrackers` (though likely redundant after deletion).
   *
   * @param ability - The CASL ability object defining the user's permissions.
   * @param eventId - The ID of the event to remove.
   * @returns A promise that resolves to true if the event was successfully deleted, false otherwise (e.g., due to permissions or if it's the default event).
   */
  async removeEvent(ability: AppAbility, eventId: string) {
    if (
      await this.prisma.eventBase.findFirst({
        where: {
          AND: [
            {
              id: eventId,
            },
            accessibleBy(ability, Action.Delete).EventBase,
          ],
        },
      })
    ) {
      const defaultOrg = await this.orgService.getDefaultOrganization(
        OrganizationSpecialUsage.DEVICE_LOGIN,
      );

      const defaultEv = await this.orgService.getDefaultEvent(defaultOrg);
      if (defaultEv.id === eventId) return false;

      await this.prisma.group.updateMany({
        where: { curEventId: eventId },
        data: { curEventId: defaultEv.id },
      });

      await this.prisma.eventBase.delete({
        where: {
          id: eventId,
        },
      });

      await this.fixEventTrackers(eventId);

      console.log(`Deleted event ${eventId}`);
      return true;
    }
    return false;
  }
}
