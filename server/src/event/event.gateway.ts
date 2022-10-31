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
import { EventService } from './event.service';
import { RequestAllEventDataDto } from './request-all-event-data.dto';
import { RequestEventDataDto } from './request-event-data.dto';
import { RequestEventLeaderDataDto } from './request-event-leader-data.dto';
import { RequestEventTrackerDataDto } from '../challenge/request-event-tracker-data.dto';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { UseGuards } from '@nestjs/common';
import { EventBase, EventRewardType, User } from '@prisma/client';

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
        ids.map(ev => this.eventService.updateEventDataDtoForEvent(ev)),
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
    const results = await this.eventService.searchEvents(
      data.offset,
      Math.min(data.count, 1024), // Maxed out at 1024 events
      data.rewardTypes.map(t =>
        t === 'limited_time_event'
          ? EventRewardType.LIMITED_TIME
          : EventRewardType.PERPETUAL,
      ),
      data.skippableOnly ? true : undefined,
      {
        time: data.closestToEnding ? 'asc' : undefined,
        challengeCount: data.shortestFirst ? 'asc' : undefined,
      },
      await this.eventService.getEventRestrictionForUser(user),
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
        progresses.map(evTracker => ({
          username: evTracker.user.username,
          userId: evTracker.user.id,
          score: evTracker.score,
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
        trackers.map(tracker => ({
          eventId: tracker.eventId,
          isRanked: tracker.isRankedForEvent,
          cooldownMinimum: tracker.cooldownEnd.toISOString(),
          curChallengeId: tracker.curChallengeId,
          prevChallengeIds: tracker.completedChallenges.map(
            pc => pc.challenge.id,
          ),
        })),
      ),
    });

    return false;
  }
}
