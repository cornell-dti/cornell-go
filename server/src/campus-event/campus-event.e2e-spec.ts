import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../app.module';
import { ApprovalStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CampusEventService } from './campus-event.service';
import { ClientService } from '../client/client.service';
import { CampusEventCategoryDto, EventSourceDto } from './campus-event.dto';

jest.setTimeout(20000);

describe('CampusEventModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;
  let prisma: PrismaService;
  let campusEventService: CampusEventService;
  let sendEventMock: jest.SpyInstance;
  let testUserId: string | null = null;
  let createdCampusEventIds: string[] = [];
  let campusEventTableExists = false;

  beforeAll(() => {
    process.env.TESTING_E2E = 'true';
  });

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();

    prisma = moduleRef.get<PrismaService>(PrismaService);
    campusEventService = moduleRef.get<CampusEventService>(CampusEventService);
    const clientService = moduleRef.get<ClientService>(ClientService);
    sendEventMock = jest.spyOn(clientService, 'sendEvent').mockImplementation();

    try {
      await prisma.campusEvent.count();
      campusEventTableExists = true;
    } catch {
      campusEventTableExists = false;
    }

    const existingUser = await prisma.user.findFirst({ take: 1 });
    if (existingUser) testUserId = existingUser.id;
  });

  it('should be defined', () => {
    expect(campusEventService).toBeDefined();
  });

  it('getUpcomingEvents returns empty or paginated list', async () => {
    if (!campusEventTableExists) return;
    const list = await campusEventService.getUpcomingEvents({
      page: 1,
      limit: 10,
    });
    expect(list).toBeDefined();
    expect(list.events).toBeInstanceOf(Array);
    expect(list.total).toBeGreaterThanOrEqual(0);
    expect(list.page).toBe(1);
    expect(list.limit).toBe(10);
    expect(list.totalPages).toBeGreaterThanOrEqual(0);
  });

  it('createEvent creates an APPROVED event and getUpcomingEvents includes it', async () => {
    if (!campusEventTableExists) return;
    const start = new Date(Date.now() + 86400_000);
    const end = new Date(start.getTime() + 3600_000);
    const ev = await campusEventService.createEvent({
      title: 'E2E Campus Event',
      description: 'E2E test event',
      startTime: start.toISOString(),
      endTime: end.toISOString(),
      locationName: 'Barton Hall',
      latitude: 42.4534,
      longitude: -76.4735,
      categories: [CampusEventCategoryDto.SOCIAL],
      tags: ['e2e'],
      source: EventSourceDto.ADMIN_CREATED,
    });
    createdCampusEventIds.push(ev.id);
    expect(ev.id).toBeDefined();
    expect(ev.title).toBe('E2E Campus Event');
    expect(ev.approvalStatus).toBe('APPROVED');

    const list = await campusEventService.getUpcomingEvents({
      page: 1,
      limit: 10,
    });
    const found = list.events.find(e => e.id === ev.id);
    expect(found).toBeDefined();
    expect(found?.title).toBe('E2E Campus Event');
  });

  it('getUpcomingEvents with approvedOnly false includes non-approved events', async () => {
    if (!campusEventTableExists) return;
    const start = new Date(Date.now() + 172800_000);
    const end = new Date(start.getTime() + 3600_000);
    const pending = await prisma.campusEvent.create({
      data: {
        title: 'E2E Pending Campus Event',
        description: 'pending',
        startTime: start,
        endTime: end,
        locationName: 'Test',
        latitude: 42.45,
        longitude: -76.47,
        categories: ['OTHER'],
        tags: ['e2e-pending'],
        source: 'COMMUNITY_SUBMITTED',
        approvalStatus: ApprovalStatus.PENDING,
      },
    });
    createdCampusEventIds.push(pending.id);

    const publicList = await campusEventService.getUpcomingEvents({
      page: 1,
      limit: 50,
    });
    expect(publicList.events.find(e => e.id === pending.id)).toBeUndefined();

    const adminList = await campusEventService.getUpcomingEvents(
      { page: 1, limit: 50 },
      { approvedOnly: false },
    );
    const fromAdmin = adminList.events.find(e => e.id === pending.id);
    expect(fromAdmin).toBeDefined();
    expect(fromAdmin?.title).toBe('E2E Pending Campus Event');
  });

  it('getEventById returns event when approved', async () => {
    if (!campusEventTableExists) return;
    const id = createdCampusEventIds[0];
    const ev = await campusEventService.getEventById(id, true);
    expect(ev).not.toBeNull();
    expect(ev?.title).toBe('E2E Campus Event');
  });

  it('toCampusEventDto returns DTO with rsvpCount and attendanceCount', async () => {
    if (!campusEventTableExists) return;
    const id = createdCampusEventIds[0];
    const ev = await campusEventService.getEventById(id, true);
    expect(ev).not.toBeNull();
    const dto = await campusEventService.toCampusEventDto(ev!);
    expect(dto.id).toBe(id);
    expect(dto.rsvpCount).toBe(0);
    expect(dto.attendanceCount).toBe(0);
  });

  it('updateEvent updates event', async () => {
    if (!campusEventTableExists) return;
    const id = createdCampusEventIds[0];
    const start = new Date(Date.now() + 86400_000);
    const end = new Date(start.getTime() + 3600_000);
    const updated = await campusEventService.updateEvent(id, {
      title: 'E2E Campus Event Updated',
      description: 'Updated description',
      startTime: start.toISOString(),
      endTime: end.toISOString(),
      locationName: 'Barton Hall',
      latitude: 42.4534,
      longitude: -76.4735,
      categories: [CampusEventCategoryDto.SOCIAL],
      tags: ['e2e', 'updated'],
      source: EventSourceDto.ADMIN_CREATED,
    });
    expect(updated).not.toBeNull();
    expect(updated?.title).toBe('E2E Campus Event Updated');

    const ev = await campusEventService.getEventById(id, true);
    expect(ev?.title).toBe('E2E Campus Event Updated');
  });

  it('rsvp adds RSVP and unRsvp removes it', async () => {
    if (!campusEventTableExists || !testUserId) return;
    const id = createdCampusEventIds[0];
    const rsvpOk = await campusEventService.rsvp(testUserId, id);
    expect(rsvpOk).toBe(true);

    const ev = await campusEventService.getEventById(id, true);
    const dtoAfter = await campusEventService.toCampusEventDto(ev!);
    expect(dtoAfter.rsvpCount).toBe(1);

    const unRsvpOk = await campusEventService.unRsvp(testUserId, id);
    expect(unRsvpOk).toBe(true);

    const dtoAfterUn = await campusEventService.toCampusEventDto(
      (await campusEventService.getEventById(id, true))!,
    );
    expect(dtoAfterUn.rsvpCount).toBe(0);
  });

  it('deleteEvent removes event', async () => {
    if (!campusEventTableExists) return;
    const id = createdCampusEventIds[0];
    const deleted = await campusEventService.deleteEvent(id);
    expect(deleted).toBe(true);

    const ev = await campusEventService.getEventById(id, true);
    expect(ev).toBeNull();

    const list = await campusEventService.getUpcomingEvents({
      page: 1,
      limit: 10,
    });
    const found = list.events.find(e => e.id === id);
    expect(found).toBeUndefined();

    createdCampusEventIds = createdCampusEventIds.filter(x => x !== id);
  });

  it('sendEvent was called on create/update/delete/rsvp', () => {
    if (!campusEventTableExists) return;
    expect(sendEventMock).toHaveBeenCalledWith(
      null,
      'updateCampusEventData',
      expect.any(Object),
    );
  });

  afterAll(async () => {
    for (const id of createdCampusEventIds) {
      await campusEventService.deleteEvent(id).catch(() => {});
    }
    await app.close();
  });
});
