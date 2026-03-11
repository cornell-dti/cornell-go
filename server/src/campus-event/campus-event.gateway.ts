import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { CallingUser } from '../auth/calling-user.decorator';
import { User } from '@prisma/client';
import { UserGuard } from '../auth/jwt-auth.guard';
import { UseGuards } from '@nestjs/common';
import { ClientService } from '../client/client.service';
import { CampusEventService } from './campus-event.service';
import {
  RequestCampusEventsDto,
  RequestCampusEventDetailsDto,
  UpsertCampusEventDto,
  DeleteCampusEventDto,
  RsvpCampusEventDto,
  UnRsvpCampusEventDto,
} from './campus-event.dto';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class CampusEventGateway {
  constructor(
    private readonly clientService: ClientService,
    private readonly campusEventService: CampusEventService,
  ) {}

  @SubscribeMessage('requestCampusEvents')
  async requestCampusEvents(
    @CallingUser() user: User,
    @MessageBody() data: RequestCampusEventsDto,
  ) {
    const list = await this.campusEventService.getUpcomingEvents(data);
    await this.clientService.sendEvent(['user/' + user.id], 'campusEventList', {
      list,
    });
    return list.totalPages;
  }

  @SubscribeMessage('requestCampusEventDetails')
  async requestCampusEventDetails(
    @CallingUser() user: User,
    @MessageBody() data: RequestCampusEventDetailsDto,
  ) {
    const ev = await this.campusEventService.getEventById(data.eventId, true);
    if (!ev) {
      await this.clientService.emitErrorData(user, 'Campus event not found.');
      return;
    }
    const dto = await this.campusEventService.toCampusEventDto(ev);
    await this.clientService.sendEvent(
      ['user/' + user.id],
      'campusEventDetails',
      { event: dto },
    );
    return dto.id;
  }

  @SubscribeMessage('createCampusEvent')
  async createCampusEvent(
    @CallingUser() user: User,
    @MessageBody() data: UpsertCampusEventDto,
  ) {
    if (!user.administrator) {
      await this.clientService.emitErrorData(user, 'Forbidden.');
      return;
    }
    const ev = await this.campusEventService.createEvent(data);
    await this.clientService.sendEvent(
      ['user/' + user.id],
      'campusEventDetails',
      { event: await this.campusEventService.toCampusEventDto(ev) },
    );
    return ev.id;
  }

  @SubscribeMessage('updateCampusEvent')
  async updateCampusEvent(
    @CallingUser() user: User,
    @MessageBody() data: UpsertCampusEventDto & { id: string },
  ) {
    if (!user.administrator) {
      await this.clientService.emitErrorData(user, 'Forbidden.');
      return;
    }
    if (!data.id) {
      await this.clientService.emitErrorData(user, 'Event id required.');
      return;
    }
    const ev = await this.campusEventService.updateEvent(data.id, data);
    if (!ev) {
      await this.clientService.emitErrorData(user, 'Event not found.');
      return;
    }
    return ev.id;
  }

  @SubscribeMessage('deleteCampusEvent')
  async deleteCampusEvent(
    @CallingUser() user: User,
    @MessageBody() data: DeleteCampusEventDto,
  ) {
    if (!user.administrator) {
      await this.clientService.emitErrorData(user, 'Forbidden.');
      return;
    }
    const ok = await this.campusEventService.deleteEvent(data.eventId);
    if (!ok) {
      await this.clientService.emitErrorData(user, 'Failed to delete event.');
      return;
    }
    return true;
  }

  @SubscribeMessage('rsvpCampusEvent')
  async rsvpCampusEvent(
    @CallingUser() user: User,
    @MessageBody() data: RsvpCampusEventDto,
  ) {
    const ok = await this.campusEventService.rsvp(user.id, data.eventId);
    if (!ok) {
      await this.clientService.emitErrorData(user, 'Failed to RSVP.');
      return;
    }
    return true;
  }

  @SubscribeMessage('unRsvpCampusEvent')
  async unRsvpCampusEvent(
    @CallingUser() user: User,
    @MessageBody() data: UnRsvpCampusEventDto,
  ) {
    const ok = await this.campusEventService.unRsvp(user.id, data.eventId);
    if (!ok) {
      await this.clientService.emitErrorData(user, 'Failed to remove RSVP.');
      return;
    }
    return true;
  }
}
