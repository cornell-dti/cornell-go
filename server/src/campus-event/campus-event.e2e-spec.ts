import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../app.module';
import { ApprovalStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CampusEventService } from './campus-event.service';
import { ClientService } from '../client/client.service';
import { RsvpReminderService } from './rsvp-reminder.service';
import { NotificationService } from '../notification/notification.service';

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
      categories: ['SOCIAL'],
      tags: ['e2e'],
      source: 'ADMIN_CREATED',
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
      categories: ['SOCIAL'],
      tags: ['e2e', 'updated'],
      source: 'ADMIN_CREATED',
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

  describe('RsvpReminderService', () => {
    let reminderService: RsvpReminderService;
    let sendToUserMock: jest.SpyInstance;
    let reminderEventId: string;

    const LEAD_TIME_MS = 3 * 60 * 60 * 1000;

    beforeAll(() => {
      reminderService = moduleRef.get<RsvpReminderService>(RsvpReminderService);
      const notificationService =
        moduleRef.get<NotificationService>(NotificationService);
      sendToUserMock = jest
        .spyOn(notificationService, 'sendToUser')
        .mockResolvedValue(true);
    });

    afterAll(async () => {
      sendToUserMock.mockRestore();
      if (reminderEventId) {
        await prisma.eventRSVP
          .deleteMany({ where: { campusEventId: reminderEventId } })
          .catch(() => {});
        await campusEventService.deleteEvent(reminderEventId).catch(() => {});
      }
    });

    it('sends reminder for RSVP within the cron window', async () => {
      if (!campusEventTableExists || !testUserId) return;

      const startTime = new Date(Date.now() + LEAD_TIME_MS + 60_000);
      const endTime = new Date(startTime.getTime() + 3600_000);

      const ev = await campusEventService.createEvent({
        title: 'Reminder Test Event',
        description: 'Testing RSVP reminders',
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        locationName: 'Duffield Hall',
        latitude: 42.4445,
        longitude: -76.4827,
        categories: ['SOCIAL'],
        tags: ['test-reminder'],
        source: 'ADMIN_CREATED',
      });
      reminderEventId = ev.id;
      createdCampusEventIds.push(ev.id);

      await campusEventService.rsvp(testUserId, ev.id);

      sendToUserMock.mockClear();
      await reminderService.handleReminderCron();

      expect(sendToUserMock).toHaveBeenCalledWith(
        testUserId,
        expect.stringContaining('Reminder Test Event'),
        expect.any(String),
        { campusEventId: ev.id },
      );

      const rsvp = await prisma.eventRSVP.findFirst({
        where: { userId: testUserId, campusEventId: ev.id },
      });
      expect(rsvp?.reminderSent).toBe(true);
    });

    it('does not send duplicate reminders', async () => {
      if (!campusEventTableExists || !testUserId || !reminderEventId) return;

      sendToUserMock.mockClear();
      await reminderService.handleReminderCron();

      expect(sendToUserMock).not.toHaveBeenCalled();
    });

    it('prevents duplicate sends during concurrent cron runs', async () => {
      if (!campusEventTableExists || !testUserId) return;

      const startTime = new Date(Date.now() + LEAD_TIME_MS + 90_000);
      const endTime = new Date(startTime.getTime() + 3600_000);
      const ev = await campusEventService.createEvent({
        title: 'Concurrent Reminder Event',
        description: 'Should only send one reminder',
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        locationName: 'Statler Hall',
        latitude: 42.4458,
        longitude: -76.4821,
        categories: ['SOCIAL'],
        tags: ['test-concurrent-reminder'],
        source: 'ADMIN_CREATED',
      });
      createdCampusEventIds.push(ev.id);

      await campusEventService.rsvp(testUserId, ev.id);

      sendToUserMock.mockClear();
      sendToUserMock.mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve(true), 100)),
      );

      await Promise.all([
        reminderService.handleReminderCron(),
        reminderService.handleReminderCron(),
      ]);

      expect(sendToUserMock).toHaveBeenCalledTimes(1);

      sendToUserMock.mockResolvedValue(true);
    });

    it('does not send reminders for events outside the window', async () => {
      if (!campusEventTableExists || !testUserId) return;

      const farFuture = new Date(Date.now() + 24 * 60 * 60 * 1000);
      const endTime = new Date(farFuture.getTime() + 3600_000);

      const ev = await campusEventService.createEvent({
        title: 'Far Future Event',
        description: 'Should not trigger reminder',
        startTime: farFuture.toISOString(),
        endTime: endTime.toISOString(),
        locationName: 'Olin Library',
        latitude: 42.4479,
        longitude: -76.4841,
        categories: ['SOCIAL'],
        tags: ['test-no-reminder'],
        source: 'ADMIN_CREATED',
      });
      createdCampusEventIds.push(ev.id);

      await campusEventService.rsvp(testUserId, ev.id);

      sendToUserMock.mockClear();
      await reminderService.handleReminderCron();

      expect(sendToUserMock).not.toHaveBeenCalledWith(
        testUserId,
        expect.stringContaining('Far Future Event'),
        expect.any(String),
        expect.any(Object),
      );

      await campusEventService.unRsvp(testUserId, ev.id);
    });
  });

  afterAll(async () => {
    for (const id of createdCampusEventIds) {
      await campusEventService.deleteEvent(id).catch(() => {});
    }
    await app.close();
  });
});
