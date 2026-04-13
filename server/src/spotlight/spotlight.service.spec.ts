import { Test, TestingModule } from '@nestjs/testing';
import { SpotlightService } from './spotlight.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';

// Helper to create a mock spotlight with sensible defaults
function mockSpotlight(overrides: Record<string, any> = {}) {
  return {
    id: 'spotlight-1',
    title: 'Test Spotlight',
    body: 'Come check this out!',
    latitude: 42.4534,
    longitude: -76.4735,
    radiusMeters: 200,
    cooldownDays: 7,
    startDate: new Date('2026-01-01'),
    endDate: new Date('2026-12-31'),
    startHour: 0,
    endHour: 24,
    isActive: true,
    linkedEventId: null,
    linkedCampusEventId: null,
    ...overrides,
  };
}

describe('SpotlightService', () => {
  let service: SpotlightService;
  let prisma: any;
  let notificationService: any;

  beforeEach(async () => {
    prisma = {
      locationSpotlight: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      spotlightNotificationLog: {
        count: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
      },
      prevChallenge: {
        findFirst: jest.fn(),
      },
      eventAttendance: {
        findFirst: jest.fn(),
      },
    };

    notificationService = {
      sendToUser: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SpotlightService,
        { provide: PrismaService, useValue: prisma },
        { provide: NotificationService, useValue: notificationService },
      ],
    }).compile();

    service = module.get<SpotlightService>(SpotlightService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('requestNotification', () => {
    const userId = 'user-1';
    const spotlightId = 'spotlight-1';
    // Location right on top of the spotlight
    const userLat = 42.4534;
    const userLng = -76.4735;

    it('should send notification when all checks pass', async () => {
      // mockResolvedValue mocks when calls that occur in this test (to test that specific scenario)
      prisma.locationSpotlight.findUnique.mockResolvedValue(mockSpotlight());
      prisma.spotlightNotificationLog.count.mockResolvedValue(0);
      prisma.spotlightNotificationLog.findFirst.mockResolvedValue(null);
      notificationService.sendToUser.mockResolvedValue(true);

      const result = await service.requestNotification(
        userId,
        spotlightId,
        userLat,
        userLng,
      );

      expect(result.sent).toBe(true);
      expect(notificationService.sendToUser).toHaveBeenCalledWith(
        userId,
        'Test Spotlight',
        'Come check this out!',
        expect.objectContaining({ spotlightId }),
      );
      expect(prisma.spotlightNotificationLog.create).toHaveBeenCalled();
    });

    it('should reject when spotlight not found', async () => {
      prisma.locationSpotlight.findUnique.mockResolvedValue(null);

      const result = await service.requestNotification(
        userId,
        spotlightId,
        userLat,
        userLng,
      );

      expect(result.sent).toBe(false);
      expect(result.reason).toContain('not found');
      expect(notificationService.sendToUser).not.toHaveBeenCalled();
    });

    it('should reject when spotlight is inactive', async () => {
      prisma.locationSpotlight.findUnique.mockResolvedValue(
        mockSpotlight({ isActive: false }),
      );

      const result = await service.requestNotification(
        userId,
        spotlightId,
        userLat,
        userLng,
      );

      expect(result.sent).toBe(false);
      expect(result.reason).toContain('inactive');
    });

    it('should reject when outside date range', async () => {
      prisma.locationSpotlight.findUnique.mockResolvedValue(
        mockSpotlight({
          startDate: new Date('2099-01-01'),
          endDate: new Date('2099-12-31'),
        }),
      );

      const result = await service.requestNotification(
        userId,
        spotlightId,
        userLat,
        userLng,
      );

      expect(result.sent).toBe(false);
      expect(result.reason).toContain('date range');
    });

    it('should reject when outside notification hours', async () => {
      // Set hours to a window that definitely doesn't include now
      // Use startHour > endHour to guarantee failure
      prisma.locationSpotlight.findUnique.mockResolvedValue(
        mockSpotlight({
          startHour: 25, // impossible hour — will always fail
          endHour: 25,
        }),
      );

      const result = await service.requestNotification(
        userId,
        spotlightId,
        userLat,
        userLng,
      );

      expect(result.sent).toBe(false);
      expect(result.reason).toContain('hours');
    });

    it('should reject when user is outside radius', async () => {
      // User is far away from spotlight
      prisma.locationSpotlight.findUnique.mockResolvedValue(mockSpotlight());

      const result = await service.requestNotification(
        userId,
        spotlightId,
        0, // equator — definitely not near Cornell
        0,
      );

      expect(result.sent).toBe(false);
      expect(result.reason).toContain('radius');
    });

    it('should reject when daily cap reached', async () => {
      prisma.locationSpotlight.findUnique.mockResolvedValue(mockSpotlight());
      prisma.spotlightNotificationLog.count.mockResolvedValue(1); // already hit cap

      const result = await service.requestNotification(
        userId,
        spotlightId,
        userLat,
        userLng,
      );

      expect(result.sent).toBe(false);
      expect(result.reason).toContain('Daily');
    });

    it('should reject when cooldown is active', async () => {
      prisma.locationSpotlight.findUnique.mockResolvedValue(mockSpotlight());
      prisma.spotlightNotificationLog.count.mockResolvedValue(0);
      prisma.spotlightNotificationLog.findFirst.mockResolvedValue({
        notifiedAt: new Date(), // notified just now
      });

      const result = await service.requestNotification(
        userId,
        spotlightId,
        userLat,
        userLng,
      );

      expect(result.sent).toBe(false);
      expect(result.reason).toContain('Cooldown');
    });

    it('should reject when linked event already completed', async () => {
      prisma.locationSpotlight.findUnique.mockResolvedValue(
        mockSpotlight({ linkedEventId: 'event-1' }),
      );
      prisma.spotlightNotificationLog.count.mockResolvedValue(0);
      prisma.spotlightNotificationLog.findFirst.mockResolvedValue(null);
      prisma.prevChallenge.findFirst.mockResolvedValue({ id: 1 }); // completed

      const result = await service.requestNotification(
        userId,
        spotlightId,
        userLat,
        userLng,
      );

      expect(result.sent).toBe(false);
      expect(result.reason).toContain('completed');
    });

    it('should reject when linked campus event already attended', async () => {
      prisma.locationSpotlight.findUnique.mockResolvedValue(
        mockSpotlight({ linkedCampusEventId: 'campus-event-1' }),
      );
      prisma.spotlightNotificationLog.count.mockResolvedValue(0);
      prisma.spotlightNotificationLog.findFirst.mockResolvedValue(null);
      prisma.eventAttendance.findFirst.mockResolvedValue({ id: 'att-1' });

      const result = await service.requestNotification(
        userId,
        spotlightId,
        userLat,
        userLng,
      );

      expect(result.sent).toBe(false);
      expect(result.reason).toContain('attended');
    });

    it('should not log when FCM send fails', async () => {
      prisma.locationSpotlight.findUnique.mockResolvedValue(mockSpotlight());
      prisma.spotlightNotificationLog.count.mockResolvedValue(0);
      prisma.spotlightNotificationLog.findFirst.mockResolvedValue(null);
      notificationService.sendToUser.mockResolvedValue(false); // FCM failed

      const result = await service.requestNotification(
        userId,
        spotlightId,
        userLat,
        userLng,
      );

      expect(result.sent).toBe(false);
      expect(result.reason).toContain('Failed');
      expect(prisma.spotlightNotificationLog.create).not.toHaveBeenCalled();
    });
  });
});
