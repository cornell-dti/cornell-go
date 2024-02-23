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
import { EventBase, EventRewardType, User } from '@prisma/client';
import {
  EventDto,
  RequestAllEventDataDto,
  RequestEventDataDto,
  RequestEventLeaderDataDto,
  UpdateEventDataDto,
  RequestRecommendedEventsDto,
} from './event.dto';
import { RequestEventTrackerDataDto } from '../challenge/challenge.dto';
import { OrganizationService } from '../organization/organization.service';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class EventGateway {
  constructor(
    private clientService: ClientService,
    private eventService: EventService,
    private orgService: OrganizationService,
  ) {}

  /**
   * Subscribes to and emits all events that have an id within data.eventIds
   *
   * @param user The calling user
   * @param data An array of event ids whose info should be emitted
   */
  @SubscribeMessage('requestEventData')
  async requestEventData(
    @CallingUser() user: User,
    @MessageBody() data: RequestEventDataDto,
  ) {
    const basic = await this.eventService.getEventsByIdsForUser(
      data.eventIds,
      false,
      user,
    );

    const admin = await this.eventService.getEventsByIdsForUser(
      data.eventIds,
      true,
      user,
    );

    for (const ev of basic) {
      this.clientService.subscribe(user, ev.id, false);
      await this.eventService.emitUpdateEventData(ev, false, false, user);
    }

    for (const ev of admin) {
      this.clientService.subscribe(user, ev.id, true);
      await this.eventService.emitUpdateEventData(ev, false, true, user);
    }
  }

  /**
   * Emits all found events and has the user subscribe to each event.
   * 
   * @param user The calling user
   * @param data Includes data such as offset, count, rewardTypes,
        closestToEnding, shortestFirst, and skippable. OnlySee game_server_api.dart for more details.
   */
  @SubscribeMessage('requestAllEventData')
  async requestAllEventData(
    @CallingUser() user: User,
    @MessageBody() data: RequestAllEventDataDto,
  ) {
    const evs = await this.eventService.getEventsForUser(user);

    for (const ev of evs) {
      this.clientService.subscribe(user, ev.id, false);
      await this.eventService.emitUpdateEventData(ev, false, false, user);
    }
  }

  @SubscribeMessage('requestRecommendedEvents')
  async requestRecommendedEvents(
    @CallingUser() user: User,
    @MessageBody() data: RequestRecommendedEventsDto,
  ) {
    const evs = await this.eventService.getRecommendedEventsForUser(user, data);
    for (const ev of evs) {
      await this.eventService.emitUpdateEventData(ev, false, false, user);
    }
  }

  @SubscribeMessage('requestEventLeaderData')
  async requestEventLeaderData(
    @CallingUser() user: User,
    @MessageBody() data: RequestEventLeaderDataDto,
  ) {
    if (!(await this.eventService.isAllowedEvent(user, data.eventId))) {
      await this.clientService.emitErrorData(user, 'Access Denied');
      return;
    }

    const ev = await this.eventService.getEventById(data.eventId);
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
      data.trackedEventIds,
    );

    for (const tracker of trackers) {
      await this.eventService.emitUpdateEventTracker(tracker);
    }
  }

  @SubscribeMessage('updateEventData')
  async updateEventData(
    @CallingUser() user: User,
    @MessageBody() data: UpdateEventDataDto,
  ) {
    if (data.deleted) {
      if (
        !(await this.eventService.hasAdminRights(
          { id: data.event as string },
          user,
        ))
      ) {
        await this.clientService.emitErrorData(
          user,
          'User has no admin rights',
        );
        return;
      }

      const ev = await this.eventService.getEventWithOrgs(data.event as string);
      await this.eventService.removeEvent(ev.id, user);
      await this.eventService.emitUpdateEventData(ev, true);
      for (const org of ev.usedIn) {
        await this.orgService.emitUpdateOrganizationData(org, false);
      }
    } else {
      const dto = data.event as EventDto;
      if (
        !(await this.orgService.isManagerOf(
          { id: dto.initialOrganizationId ?? '' },
          user,
        )) &&
        !(await this.eventService.hasAdminRights({ id: dto.id }, user))
      ) {
        await this.clientService.emitErrorData(
          user,
          'User has no admin rights',
        );
        return;
      }

      const ev = await this.eventService.upsertEventFromDto(
        data.event as EventDto,
      );

      const org = await this.orgService.getOrganizationById(
        dto.initialOrganizationId!,
      );

      await this.orgService.emitUpdateOrganizationData(org, false);
      await this.eventService.emitUpdateEventData(ev, false);
    }
  }
}
