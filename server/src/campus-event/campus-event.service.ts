import { Injectable } from '@nestjs/common';
import { CampusEvent, ApprovalStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ClientService } from '../client/client.service';
import {
  CampusEventDto,
  CampusEventListDto,
  RequestCampusEventsDto,
  UpsertCampusEventDto,
} from './campus-event.dto';

@Injectable()
export class CampusEventService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clientService: ClientService,
  ) {}

  /** Map Prisma model to API DTO with counts */
  async toCampusEventDto(ev: CampusEvent): Promise<CampusEventDto> {
    const [attendanceCount, rsvpCount] = await Promise.all([
      this.prisma.eventAttendance.count({ where: { campusEventId: ev.id } }),
      this.prisma.eventRSVP.count({ where: { campusEventId: ev.id } }),
    ]);
    return {
      id: ev.id,
      title: ev.title,
      description: ev.description,
      imageUrl: ev.imageUrl ?? undefined,
      startTime: ev.startTime.toISOString(),
      endTime: ev.endTime.toISOString(),
      allDay: ev.allDay,
      locationName: ev.locationName,
      address: ev.address ?? undefined,
      latitude: ev.latitude,
      longitude: ev.longitude,
      categories: ev.categories,
      tags: ev.tags,
      source: ev.source,
      externalUrl: ev.externalUrl ?? undefined,
      organizerName: ev.organizerName ?? undefined,
      registrationUrl: ev.registrationUrl ?? undefined,
      checkInMethod: ev.checkInMethod,
      pointsForAttendance: ev.pointsForAttendance,
      featured: ev.featured,
      attendanceCount,
      rsvpCount,
    };
  }

  /** Get paginated upcoming events with filters (only APPROVED) */
  async getUpcomingEvents(
    dto: RequestCampusEventsDto,
  ): Promise<CampusEventListDto> {
    const { page, limit, dateFrom, dateTo, categories, search, featured } = dto;
    const skip = (page - 1) * limit;

    const where: any = {
      approvalStatus: ApprovalStatus.APPROVED,
    };

    if (dateFrom || dateTo) {
      where.startTime = {};
      if (dateFrom) where.startTime.gte = new Date(dateFrom);
      if (dateTo) where.startTime.lte = new Date(dateTo);
    }
    if (categories?.length) {
      where.categories = { hasSome: categories };
    }
    if (featured === true) {
      where.featured = true;
    }
    if (search?.trim()) {
      where.OR = [
        { title: { contains: search.trim(), mode: 'insensitive' } },
        { description: { contains: search.trim(), mode: 'insensitive' } },
      ];
    }

    const [events, total] = await Promise.all([
      this.prisma.campusEvent.findMany({
        where,
        orderBy: { startTime: 'asc' },
        skip,
        take: limit,
      }),
      this.prisma.campusEvent.count({ where }),
    ]);

    const eventDtos = await Promise.all(
      events.map(ev => this.toCampusEventDto(ev)),
    );

    return {
      events: eventDtos,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
    };
  }

  /** Get a single event by id (only APPROVED for public, or any for admin) */
  async getEventById(
    eventId: string,
    approvedOnly = true,
  ): Promise<CampusEvent | null> {
    const where: any = { id: eventId };
    if (approvedOnly) where.approvalStatus = ApprovalStatus.APPROVED;
    return this.prisma.campusEvent.findFirst({ where });
  }

  /** Create a new campus event */
  async createEvent(dto: UpsertCampusEventDto): Promise<CampusEvent> {
    const ev = await this.prisma.campusEvent.create({
      data: {
        title: dto.title,
        description: dto.description,
        imageUrl: dto.imageUrl,
        startTime: new Date(dto.startTime),
        endTime: new Date(dto.endTime),
        allDay: dto.allDay ?? false,
        locationName: dto.locationName,
        address: dto.address,
        latitude: dto.latitude,
        longitude: dto.longitude,
        checkInRadius: dto.checkInRadius ?? 100,
        categories: dto.categories,
        tags: dto.tags,
        source: dto.source,
        externalId: dto.externalId,
        externalUrl: dto.externalUrl,
        organizerName: dto.organizerName,
        organizerEmail: dto.organizerEmail,
        organizerId: dto.organizerId,
        checkInMethod: dto.checkInMethod ?? 'EITHER',
        pointsForAttendance: dto.pointsForAttendance ?? 10,
        featured: dto.featured ?? false,
        registrationUrl: dto.registrationUrl,
        approvalStatus: ApprovalStatus.APPROVED,
      },
    });
    await this.emitUpdateCampusEvent(ev, false);
    return ev;
  }

  /** Update an existing campus event */
  async updateEvent(
    eventId: string,
    dto: UpsertCampusEventDto,
  ): Promise<CampusEvent | null> {
    const existing = await this.prisma.campusEvent.findUnique({
      where: { id: eventId },
    });
    if (!existing) return null;

    const ev = await this.prisma.campusEvent.update({
      where: { id: eventId },
      data: {
        title: dto.title,
        description: dto.description,
        imageUrl: dto.imageUrl,
        startTime: new Date(dto.startTime),
        endTime: new Date(dto.endTime),
        allDay: dto.allDay ?? false,
        locationName: dto.locationName,
        address: dto.address,
        latitude: dto.latitude,
        longitude: dto.longitude,
        checkInRadius: dto.checkInRadius ?? 100,
        categories: dto.categories,
        tags: dto.tags,
        source: dto.source,
        externalId: dto.externalId,
        externalUrl: dto.externalUrl,
        organizerName: dto.organizerName,
        organizerEmail: dto.organizerEmail,
        organizerId: dto.organizerId,
        checkInMethod: dto.checkInMethod ?? 'EITHER',
        pointsForAttendance: dto.pointsForAttendance ?? 10,
        featured: dto.featured ?? false,
        registrationUrl: dto.registrationUrl,
      },
    });
    await this.emitUpdateCampusEvent(ev, false);
    return ev;
  }

  /** Delete a campus event */
  async deleteEvent(eventId: string): Promise<boolean> {
    const existing = await this.prisma.campusEvent.findUnique({
      where: { id: eventId },
    });
    if (!existing) return false;

    await this.prisma.campusEvent.delete({ where: { id: eventId } });
    await this.emitUpdateCampusEvent(existing, true);
    return true;
  }

  /** Add RSVP for user to event */
  async rsvp(userId: string, eventId: string): Promise<boolean> {
    const event = await this.getEventById(eventId, true);
    if (!event) return false;

    await this.prisma.eventRSVP.upsert({
      where: {
        userId_campusEventId: { userId, campusEventId: eventId },
      },
      create: { userId, campusEventId: eventId },
      update: {},
    });
    const updated = await this.prisma.campusEvent.findUnique({
      where: { id: eventId },
    });
    if (updated) await this.emitUpdateCampusEvent(updated, false);
    return true;
  }

  /** Remove RSVP for user from event */
  async unRsvp(userId: string, eventId: string): Promise<boolean> {
    const deleted = await this.prisma.eventRSVP.deleteMany({
      where: { userId, campusEventId: eventId },
    });
    if (deleted.count === 0) return false;
    const updated = await this.prisma.campusEvent.findUnique({
      where: { id: eventId },
    });
    if (updated) await this.emitUpdateCampusEvent(updated, false);
    return true;
  }

  /** Broadcast single event update to all connected clients */
  async emitUpdateCampusEvent(
    ev: CampusEvent,
    deleted: boolean,
  ): Promise<void> {
    const dto = deleted
      ? { event: { id: ev.id }, deleted: true }
      : {
          event: await this.toCampusEventDto(ev),
          deleted: false,
        };
    await this.clientService.sendEvent<typeof dto>(
      null,
      'updateCampusEventData',
      dto,
    );
  }
}
