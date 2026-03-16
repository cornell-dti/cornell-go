import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../app.module';
import { EventSyncService } from './event-sync.service';
import { PrismaService } from '../prisma/prisma.service';
import { ApprovalStatus, EventSource } from '@prisma/client';

function makeLocalistEvent(overrides: Record<string, any> = {}) {
  const id = overrides.id ?? Math.floor(Math.random() * 1_000_000);
  const future = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);

  return {
    id,
    title: overrides.title ?? `Test Event ${id}`,
    description_text: overrides.description_text ?? 'A test event description',
    description: overrides.description ?? '<p>A test event description</p>',
    photo_url: overrides.photo_url ?? 'https://example.com/photo.jpg',
    location_name: overrides.location_name ?? 'Olin Library',
    address: overrides.address ?? '161 Ho Plaza, Ithaca, NY',
    geo:
      'geo' in overrides
        ? overrides.geo
        : {
            latitude: '42.4479',
            longitude: '-76.4841',
          },
    tags: overrides.tags ?? ['test'],
    keywords: overrides.keywords ?? [],
    filters: overrides.filters ?? {
      event_types: [{ id: 1, name: 'Lecture' }],
      departments: [{ id: 100, name: 'Computer Science' }],
    },
    localist_url:
      overrides.localist_url ?? `https://events.cornell.edu/event/${id}`,
    ticket_url: overrides.ticket_url ?? '',
    featured: overrides.featured ?? false,
    updated_at: overrides.updated_at ?? new Date().toISOString(),
    event_instances: overrides.event_instances ?? [
      {
        event_instance: {
          id: id * 10,
          start: future.toISOString(),
          end: new Date(future.getTime() + 60 * 60 * 1000).toISOString(),
          all_day: false,
          event_id: id,
        },
      },
    ],
  };
}

function makeLocalistResponse(events: any[], page = 1, totalPages = 1) {
  return {
    data: {
      events: events.map(e => ({ event: e })),
      page: { current: page, size: 100, total: totalPages },
    },
  };
}

describe('EventSyncModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;
  let syncService: EventSyncService;
  let prisma: PrismaService;

  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();

    syncService = moduleRef.get<EventSyncService>(EventSyncService);
    prisma = moduleRef.get<PrismaService>(PrismaService);
  });

  afterEach(async () => {
    await prisma.campusEvent.deleteMany({
      where: { source: EventSource.API_EVENTS },
    });
  });

  afterAll(async () => {
    await app.close();
  });

  it('should resolve EventSyncService', () => {
    expect(syncService).toBeDefined();
  });

  it('should create new events from Localist data', async () => {
    const mockEvents = [
      makeLocalistEvent({ id: 1001, title: 'CS 4120 Lecture' }),
      makeLocalistEvent({ id: 1002, title: 'Chimes Concert' }),
    ];

    jest
      .spyOn(syncService as any, 'fetchAllEvents')
      .mockResolvedValueOnce(mockEvents);

    const result = await syncService.syncEvents();

    expect(result.created).toBe(2);
    expect(result.updated).toBe(0);

    const dbEvents = await prisma.campusEvent.findMany({
      where: { source: EventSource.API_EVENTS },
    });
    expect(dbEvents).toHaveLength(2);

    const lecture = dbEvents.find(e => e.externalId === '1001');
    expect(lecture).toBeDefined();
    expect(lecture!.title).toBe('CS 4120 Lecture');
    expect(lecture!.source).toBe(EventSource.API_EVENTS);
    expect(lecture!.approvalStatus).toBe(ApprovalStatus.APPROVED);
  });

  it('should skip unchanged events on re-sync', async () => {
    const fixedDate = new Date('2026-01-01T00:00:00Z');
    const mockEvent = makeLocalistEvent({
      id: 2001,
      title: 'Recurring Seminar',
      updated_at: fixedDate.toISOString(),
    });

    jest
      .spyOn(syncService as any, 'fetchAllEvents')
      .mockResolvedValue([mockEvent]);

    const first = await syncService.syncEvents();
    expect(first.created).toBe(1);

    const second = await syncService.syncEvents();
    expect(second.created).toBe(0);
    expect(second.updated).toBe(0);

    const dbEvents = await prisma.campusEvent.findMany({
      where: { externalId: '2001' },
    });
    expect(dbEvents).toHaveLength(1);
  });

  it('should update events when Localist updated_at is newer', async () => {
    const oldDate = new Date('2026-01-01T00:00:00Z');
    const newDate = new Date('2026-06-01T00:00:00Z');

    const original = makeLocalistEvent({
      id: 3001,
      title: 'Original Title',
      updated_at: oldDate.toISOString(),
    });

    jest
      .spyOn(syncService as any, 'fetchAllEvents')
      .mockResolvedValueOnce([original]);
    await syncService.syncEvents();

    const updated = makeLocalistEvent({
      id: 3001,
      title: 'Updated Title',
      updated_at: newDate.toISOString(),
    });

    jest
      .spyOn(syncService as any, 'fetchAllEvents')
      .mockResolvedValueOnce([updated]);
    const result = await syncService.syncEvents();

    expect(result.updated).toBe(1);
    expect(result.created).toBe(0);

    const dbEvent = await prisma.campusEvent.findUnique({
      where: { externalId: '3001' },
    });
    expect(dbEvent!.title).toBe('Updated Title');
  });

  it('should archive past events', async () => {
    const pastDate = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000);
    const pastEvent = makeLocalistEvent({
      id: 4001,
      title: 'Past Event',
      event_instances: [
        {
          event_instance: {
            id: 40010,
            start: new Date(pastDate.getTime() - 60 * 60 * 1000).toISOString(),
            end: pastDate.toISOString(),
            all_day: false,
            event_id: 4001,
          },
        },
      ],
    });

    jest
      .spyOn(syncService as any, 'fetchAllEvents')
      .mockResolvedValueOnce([pastEvent]);
    const result = await syncService.syncEvents();

    expect(result.created).toBe(1);
    expect(result.archived).toBeGreaterThanOrEqual(1);

    const dbEvent = await prisma.campusEvent.findUnique({
      where: { externalId: '4001' },
    });
    expect(dbEvent!.approvalStatus).toBe(ApprovalStatus.ARCHIVED);
  });

  it('should map Localist fields correctly', async () => {
    const future = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000);

    const event = makeLocalistEvent({
      id: 5001,
      title: 'Mapped Event',
      description_text: 'Plain text description',
      photo_url: 'https://example.com/image.jpg',
      location_name: 'Sage Hall',
      address: '114 East Ave, Ithaca, NY',
      geo: { latitude: '42.4470', longitude: '-76.4830' },
      tags: ['business', 'entrepreneurship'],
      keywords: ['startup'],
      filters: {
        event_types: [{ id: 10, name: 'Career' }],
        departments: [{ id: 200, name: 'SC Johnson College of Business' }],
      },
      featured: true,
      ticket_url: 'https://tickets.example.com',
      event_instances: [
        {
          event_instance: {
            id: 50010,
            start: future.toISOString(),
            end: new Date(future.getTime() + 2 * 60 * 60 * 1000).toISOString(),
            all_day: false,
            event_id: 5001,
          },
        },
      ],
    });

    jest
      .spyOn(syncService as any, 'fetchAllEvents')
      .mockResolvedValueOnce([event]);
    await syncService.syncEvents();

    const dbEvent = await prisma.campusEvent.findUnique({
      where: { externalId: '5001' },
    });
    expect(dbEvent).toBeDefined();
    expect(dbEvent!.title).toBe('Mapped Event');
    expect(dbEvent!.description).toBe('Plain text description');
    expect(dbEvent!.imageUrl).toBe('https://example.com/image.jpg');
    expect(dbEvent!.locationName).toBe('Sage Hall');
    expect(dbEvent!.address).toBe('114 East Ave, Ithaca, NY');
    expect(dbEvent!.latitude).toBeCloseTo(42.447, 2);
    expect(dbEvent!.longitude).toBeCloseTo(-76.483, 2);
    expect(dbEvent!.tags).toEqual(
      expect.arrayContaining(['business', 'entrepreneurship', 'startup']),
    );
    expect(dbEvent!.categories).toContain('CAREER');
    expect(dbEvent!.featured).toBe(true);
    expect(dbEvent!.registrationUrl).toBe('https://tickets.example.com');
    expect(dbEvent!.organizerName).toBe('SC Johnson College of Business');
    expect(dbEvent!.externalUrl).toBe('https://events.cornell.edu/event/5001');
  });

  it('should use fallback when description_text is empty', async () => {
    const event = makeLocalistEvent({
      id: 6001,
      description_text: '',
    });

    jest
      .spyOn(syncService as any, 'fetchAllEvents')
      .mockResolvedValueOnce([event]);
    await syncService.syncEvents();

    const dbEvent = await prisma.campusEvent.findUnique({
      where: { externalId: '6001' },
    });
    expect(dbEvent!.description).toBe('No description available');
  });

  it('should use default coordinates when geo is missing', async () => {
    const event = makeLocalistEvent({
      id: 7001,
      geo: undefined,
    });

    jest
      .spyOn(syncService as any, 'fetchAllEvents')
      .mockResolvedValueOnce([event]);
    await syncService.syncEvents();

    const dbEvent = await prisma.campusEvent.findUnique({
      where: { externalId: '7001' },
    });
    expect(dbEvent!.latitude).toBeCloseTo(42.4534, 2);
    expect(dbEvent!.longitude).toBeCloseTo(-76.4735, 2);
  });

  it('should handle events with no end time by defaulting to start + 1 hour', async () => {
    const future = new Date(Date.now() + 4 * 24 * 60 * 60 * 1000);
    const event = makeLocalistEvent({
      id: 8001,
      event_instances: [
        {
          event_instance: {
            id: 80010,
            start: future.toISOString(),
            end: null,
            all_day: false,
            event_id: 8001,
          },
        },
      ],
    });

    jest
      .spyOn(syncService as any, 'fetchAllEvents')
      .mockResolvedValueOnce([event]);
    await syncService.syncEvents();

    const dbEvent = await prisma.campusEvent.findUnique({
      where: { externalId: '8001' },
    });
    const diff = dbEvent!.endTime.getTime() - dbEvent!.startTime.getTime();
    expect(diff).toBe(60 * 60 * 1000);
  });

  it('should return totalFetched in sync stats', async () => {
    const events = [
      makeLocalistEvent({ id: 9001 }),
      makeLocalistEvent({ id: 9002 }),
      makeLocalistEvent({ id: 9003 }),
    ];

    jest
      .spyOn(syncService as any, 'fetchAllEvents')
      .mockResolvedValueOnce(events);

    const result = await syncService.syncEvents();
    expect(result.totalFetched).toBe(3);
    expect(result.created).toBe(3);
  });
});
