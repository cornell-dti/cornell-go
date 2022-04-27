import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import {
  RewardTypeDto,
  UpdateEventDataDto,
} from '../client/update-event-data.dto';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { User } from '../model/user.entity';
import { EventService } from './event.service';
import { RequestAllEventDataDto } from './request-all-event-data.dto';
import { RequestEventDataDto } from './request-event-data.dto';
import { RequestEventLeaderDataDto } from './request-event-leader-data.dto';
import { EventBase, EventRewardType } from '../model/event-base.entity';
import { RequestEventTrackerDataDto } from '../challenge/request-event-tracker-data.dto';
import { EventTracker } from 'src/model/event-tracker.entity';
import { Challenge } from 'src/model/challenge.entity';
import { EventReward } from 'src/model/event-reward.entity';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { UseGuards } from '@nestjs/common';
@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class EventGateway {
  constructor(
    private clientService: ClientService,
    private eventService: EventService,
  ) {}

  @SubscribeMessage('requestEventData')
  async requestEventData(
    @CallingUser() user: User,
    @MessageBody() data: RequestEventDataDto & { isSearch?: boolean },
  ) {
    const ids = await this.eventService.getEventsByIds(data.eventIds);

    const updateEventData: UpdateEventDataDto = {
      isSearch: !!data.isSearch,
      events: await Promise.all(
        ids.map(async (ev: EventBase) => ({
          id: ev.id,
          skippingEnabled: ev.skippingEnabled,
          name: ev.name,
          description: ev.description,
          rewardType: ev.rewardType as RewardTypeDto,
          time: ev.time.toISOString(),
          requiredMembers: ev.requiredMembers,
          challengeIds: (
            await ev.challenges.loadItems()
          ).map((ch: Challenge) => ch.id),
          rewards: (
            await ev.rewards.loadItems()
          )
            .filter(rw => !rw.claimingUser)
            .map((rw: EventReward) => ({
              id: rw.id,
              description: rw.rewardDescription,
            })),
        })),
      ),
    };

    this.clientService.emitUpdateEventData(user, updateEventData);

    return false;
  }

  @SubscribeMessage('requestAllEventData')
  async requestAllEventData(
    @CallingUser() user: User,
    @MessageBody() data: RequestAllEventDataDto,
  ) {
    const restriction = await user.restrictedBy?.load();
    const restrictedCount = await restriction?.allowedEvents.loadCount();
    const searchRestriction = restrictedCount === 0 ? undefined : restriction;

    const results = await this.eventService.searchEvents(
      data.offset,
      Math.min(data.count, 1024), // Maxed out at 1024 events
      data.rewardTypes as EventRewardType[],
      data.skippableOnly ? true : undefined,
      {
        time: data.closestToEnding ? 'ASC' : undefined,
        challengeCount: data.shortestFirst ? 'ASC' : undefined,
      },
      searchRestriction,
    );

    await this.requestEventData(user, {
      isSearch: true,
      eventIds: results,
    });

    return false;
  }

  @SubscribeMessage('requestEventLeaderData')
  async requestEventLeaderData(
    @CallingUser() user: User,
    @MessageBody() data: RequestEventLeaderDataDto,
  ) {
    if (!(await this.eventService.isAllowedEvent(user, data.eventId))) {
      return;
    }

    const progresses = await this.eventService.getTopTrackersForEvent(
      data.eventId,
      data.offset,
      data.count,
    );

    this.clientService.emitUpdateLeaderData(user, {
      eventId: data.eventId,
      offset: data.offset,
      users: await Promise.all(
        progresses.map(async (evTracker: EventTracker) => ({
          username: (await evTracker.user.load()).username,
          userId: evTracker.user.id,
          score: evTracker.eventScore,
        })),
      ),
    });
  }

  @SubscribeMessage('requestEventTrackerData')
  async requestEventTrackerData(
    @CallingUser() user: User,
    @MessageBody() data: RequestEventTrackerDataDto,
  ) {
    const trackers = await this.eventService.getEventTrackersByEventId(
      user,
      data.trackedEventIds,
    );

    this.clientService.emitUpdateEventTrackerData(user, {
      eventTrackers: await Promise.all(
        trackers.map(async (tracker: EventTracker) => ({
          eventId: tracker.event.id,
          isRanked: tracker.isPlayerRanked,
          cooldownMinimum: tracker.cooldownMinimum.toISOString(),
          curChallengeId: tracker.currentChallenge.id,
          prevChallengeIds: (
            await tracker.completed.loadItems()
          ).map(pc => pc.challenge.id),
        })),
      ),
    });

    return false;
  }
}
