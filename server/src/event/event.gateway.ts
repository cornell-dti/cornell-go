import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';

import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { EventService } from './event.service';
import { UserService } from '../user/user.service';
import { UserGuard } from '../auth/jwt-auth.guard';
import { UseGuards } from '@nestjs/common';
import { EventBase, TimeLimitationType, User } from '@prisma/client';
import {
  EventDto,
  RequestAllEventDataDto,
  RequestEventDataDto,
  RequestEventLeaderDataDto,
  UpdateEventDataDto,
  RequestRecommendedEventsDto,
  UseEventTrackerHintDto,
} from './event.dto';
import { RequestEventTrackerDataDto } from '../challenge/challenge.dto';
import { OrganizationService } from '../organization/organization.service';
import { PoliciesGuard } from '../casl/policy.guard';
import { UserAbility } from '../casl/user-ability.decorator';
import { AppAbility } from '../casl/casl-ability.factory';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class EventGateway {
  constructor(
    private clientService: ClientService,
    private eventService: EventService,
    private orgService: OrganizationService,
  ) {}

  /**
   * Subscribes to and emits all events that have an id within data.events
   *
   * @param user The calling user
   * @param data An array of event ids whose info should be emitted
   */
  @SubscribeMessage('requestEventData')
  async requestEventData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: RequestEventDataDto,
  ) {
    const evs = await this.eventService.getEventsByIdsForAbility(
      ability,
      data.events,
    );

    for (const ev of evs) {
      await this.eventService.emitUpdateEventData(ev, false, user);
    }
  }

  @SubscribeMessage('requestRecommendedEvents')
  async requestRecommendedEvents(
    @CallingUser() user: User,
    @MessageBody() data: RequestRecommendedEventsDto,
  ) {
    const evs = await this.eventService.getRecommendedEventsForUser(user, data);
    for (const ev of evs) {
      await this.eventService.emitUpdateEventData(ev, false, user);
    }
  }

  @SubscribeMessage('requestEventLeaderData')
  async requestEventLeaderData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: RequestEventLeaderDataDto,
  ) {
    const ev = await this.eventService.getEventById(data.eventId);
    if (!ev) {
      await this.clientService.emitErrorData(
        user,
        'Cannot find requested event!',
      );
      return;
    }

    await this.eventService.emitUpdateLeaderData(
      data.offset,
      Math.min(data.count, 1024),
      ev,
      user,
    );
  }

  @SubscribeMessage('requestEventTrackerData')
  async requestEventTrackerData(
    @CallingUser() user: User,
    @MessageBody() data: RequestEventTrackerDataDto,
  ) {
    const trackers = await this.eventService.getEventTrackersByEventId(
      user,
      data.trackedEvents,
    );

    for (const tracker of trackers) {
      await this.eventService.emitUpdateEventTracker(tracker, user);
    }
  }

  @SubscribeMessage('useEventTrackerHint')
  async useEventTrackerHint(
    @CallingUser() user: User,
    @MessageBody() data: UseEventTrackerHintDto,
  ) {
    console.log("use event tracker hint called");
    const tracker = await this.eventService.useEventTrackerHint(user, data);
    if (tracker) {
      await this.eventService.emitUpdateEventTracker(tracker, user);
      console.log("emitted update tracker event, " + tracker.curChallengeId);
      return;
    }
    await this.clientService.emitErrorData(user, 'Failed to track used hint!');
  }

  @SubscribeMessage('updateEventData')
  async updateEventData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: UpdateEventDataDto,
  ) {
    const ev = await this.eventService.getEventById(data.event.id);

    if (data.deleted && ev) {
      if (!(await this.eventService.removeEvent(ability, ev.id))) {
        await this.clientService.emitErrorData(user, 'Failed to delete event!');
        return;
      }
      await this.eventService.emitUpdateEventData(ev, true);
    } else {
      const ev = await this.eventService.upsertEventFromDto(
        ability,
        data.event,
      );

      if (!ev) {
        await this.clientService.emitErrorData(user, 'Failed to upsert event!');
        return;
      }

      const org = await this.orgService.getOrganizationById(
        data.event.initialOrganizationId!,
      );

      this.clientService.subscribe(user, ev.id);
      await this.orgService.emitUpdateOrganizationData(org, false);
      await this.eventService.emitUpdateEventData(ev, false);
    }
  }
}
