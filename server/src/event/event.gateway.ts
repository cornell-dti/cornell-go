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
import { EventRewardType } from '../model/event-base.entity';
import { RequestEventTrackerDataDto } from '../challenge/request-event-tracker-data.dto';

@WebSocketGateway()
export class EventGateway {
  constructor(
    private clientService: ClientService,
    private eventService: EventService,
  ) {}

  @SubscribeMessage('requestEventData')
  async requestEventData(
    @CallingUser() user: User,
    @MessageBody() data: RequestEventDataDto,
  ) {
    const ids = await this.eventService.getEventsByIds(data.eventIds, true);
    const updateEventData: UpdateEventDataDto = {
      events: ids.map(ev => ({
        id: ev.id,
        skippingEnabled: ev.skippingEnabled,
        hasStarChallenge: ev.hasStarChallenge,
        name: ev.name,
        description: ev.description,
        rewardType: ev.rewardType as RewardTypeDto,
        time: ev.time.toUTCString(),
        minMembers: ev.minMembers,
        topCount: ev.topCount,
        challengeIds: ev.challenges.map(ch => ch.id),
        rewards: ev.rewards.map(rw => ({
          id: rw.id,
          description: rw.rewardDescription,
        })),
      })),
    };

    this.clientService.emitUpdateEventData(user, updateEventData);

    return true;
  }

  @SubscribeMessage('requestAllEventData')
  async requestAllEventData(
    @CallingUser() user: User,
    @MessageBody() data: RequestAllEventDataDto,
  ) {
    const results = await this.eventService.searchEvents(
      data.offset,
      Math.min(data.count, 32), // Maxed out at 32 events
      data.rewardTypes as EventRewardType[],
      data.skippableOnly ? true : undefined,
      {
        time: data.closestToEnding ? 'ASC' : undefined,
        challengeCount: data.shortestFirst ? 'ASC' : undefined,
      },
    );

    await this.requestEventData(user, {
      accessToken: data.accessToken,
      eventIds: results,
    });

    return true;
  }

  @SubscribeMessage('requestEventLeaderData')
  async requestEventLeaderData(
    @CallingUser() user: User,
    @MessageBody() data: RequestEventLeaderDataDto,
  ) {
    const progresses = await this.eventService.getTopTrackerForEvent(
      data.eventId,
      data.offset,
      data.count,
      true,
    );

    await this.clientService.emitUpdateLeaderData(user, {
      eventId: data.eventId,
      offset: data.offset,
      users: progresses.map(evTracker => ({
        username: evTracker.user.username,
        userId: evTracker.user.id,
        score: evTracker.eventScore,
      })),
    });

    return true;
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
      eventTrackers: trackers.map(tracker => ({
        eventId: tracker.event.id,
        isRanked: tracker.isPlayerRanked,
        cooldownMinimum: tracker.cooldownMinimum.toUTCString(),
        curChallengeId: tracker.currentChallenge.id,
        prevChallengeIds: tracker.completed.map(pc => pc.challenge.id),
      })),
    });

    return true;
  }
}
