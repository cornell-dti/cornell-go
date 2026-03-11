import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../app.module';
import { CheckInService } from './check-in.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { AuthType, User } from '@prisma/client';

describe('CheckInModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;
  let checkInService: CheckInService;
  let prisma: PrismaService;
  let userService: UserService;
  let user: User;

  let activeEventId: string;
  let futureEventId: string;
  let pastEventId: string;
  let qrEventId: string;
  let qrCode: string;

  beforeAll(async () => {
    process.env.TESTING_E2E = 'true';

    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();

    checkInService = moduleRef.get<CheckInService>(CheckInService);
    prisma = moduleRef.get<PrismaService>(PrismaService);
    userService = moduleRef.get<UserService>(UserService);

    user = await userService.register(
      `checkin-test-${Date.now()}@test.com`,
      `checkin-user-${Date.now()}`,
      '2025',
      'Engineering',
      'Computer Science',
      ['Testing'],
      42.4474,
      -76.4848,
      AuthType.DEVICE,
      `checkin-auth-${Date.now()}`,
      'UNDERGRADUATE',
    );

    user = await prisma.user.findFirstOrThrow({
      where: { id: user.id },
    });

    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
    const oneHourLater = new Date(now.getTime() + 60 * 60 * 1000);
    const twoHoursAgo = new Date(now.getTime() - 2 * 60 * 60 * 1000);
    const twoHoursLater = new Date(now.getTime() + 2 * 60 * 60 * 1000);

    const activeEvent = await prisma.campusEvent.create({
      data: {
        title: 'Active Test Event',
        description: 'Event currently happening',
        locationName: 'Test Location',
        latitude: 42.4474,
        longitude: -76.4848,
        checkInRadius: 100,
        startTime: oneHourAgo,
        endTime: oneHourLater,
        source: 'ADMIN_CREATED',
        approvalStatus: 'APPROVED',
        checkInMethod: 'EITHER',
        pointsForAttendance: 15,
        categories: [],
        tags: [],
      },
    });
    activeEventId = activeEvent.id;

    const futureEvent = await prisma.campusEvent.create({
      data: {
        title: 'Future Test Event',
        description: 'Event not yet started',
        locationName: 'Future Location',
        latitude: 42.4474,
        longitude: -76.4848,
        checkInRadius: 100,
        startTime: twoHoursLater,
        endTime: new Date(twoHoursLater.getTime() + 60 * 60 * 1000),
        source: 'ADMIN_CREATED',
        approvalStatus: 'APPROVED',
        checkInMethod: 'EITHER',
        pointsForAttendance: 10,
        categories: [],
        tags: [],
      },
    });
    futureEventId = futureEvent.id;

    const pastEvent = await prisma.campusEvent.create({
      data: {
        title: 'Past Test Event',
        description: 'Event already ended',
        locationName: 'Past Location',
        latitude: 42.4474,
        longitude: -76.4848,
        checkInRadius: 100,
        startTime: twoHoursAgo,
        endTime: oneHourAgo,
        source: 'ADMIN_CREATED',
        approvalStatus: 'APPROVED',
        checkInMethod: 'EITHER',
        pointsForAttendance: 10,
        categories: [],
        tags: [],
      },
    });
    pastEventId = pastEvent.id;

    const qrEvent = await prisma.campusEvent.create({
      data: {
        title: 'QR Test Event',
        description: 'Event for QR check-in',
        locationName: 'QR Location',
        latitude: 42.4474,
        longitude: -76.4848,
        checkInRadius: 100,
        startTime: oneHourAgo,
        endTime: oneHourLater,
        source: 'ADMIN_CREATED',
        approvalStatus: 'APPROVED',
        checkInMethod: 'EITHER',
        pointsForAttendance: 20,
        categories: [],
        tags: [],
      },
    });
    qrEventId = qrEvent.id;
    qrCode = await checkInService.generateQrCodeForEvent(qrEventId);
  });

  afterAll(async () => {
    try {
      if (prisma && user?.id) {
        await prisma.eventAttendance.deleteMany({
          where: { userId: user.id },
        });
        if (activeEventId && futureEventId && pastEventId && qrEventId) {
          await prisma.campusEvent.deleteMany({
            where: {
              id: {
                in: [activeEventId, futureEventId, pastEventId, qrEventId],
              },
            },
          });
        }
        await prisma.user.delete({
          where: { id: user.id },
        });
      }
    } catch {
      // Cleanup may fail if db was never connected
    }
    if (app) await app.close();
  });

  it('should successfully find CheckInService', () => {
    expect(checkInService).toBeDefined();
  });

  describe('generateQrCodeForEvent', () => {
    it('should generate and persist a unique QR code for an event', async () => {
      const qrCode = await checkInService.generateQrCodeForEvent(activeEventId);

      expect(qrCode).toBeDefined();
      expect(typeof qrCode).toBe('string');
      expect(qrCode.length).toBeGreaterThan(0);

      const event = await prisma.campusEvent.findUnique({
        where: { id: activeEventId },
      });
      expect(event.qrCode).toBe(qrCode);
    });

    it('should throw when event not found', async () => {
      await expect(
        checkInService.generateQrCodeForEvent('non-existent-id'),
      ).rejects.toThrow('Campus event not found');
    });
  });

  describe('checkInByLocation', () => {
    it('should check in when user is within radius and award points', async () => {
      const initialScore = user.score;
      const countBefore = await prisma.eventAttendance.count({
        where: { userId: user.id, campusEventId: activeEventId },
      });
      expect(countBefore).toBe(0);

      const result = await checkInService.checkInByLocation(user, {
        campusEventId: activeEventId,
        latitude: 42.4474,
        longitude: -76.4848,
      });

      expect(result.attendanceId).toBeDefined();
      expect(result.campusEventId).toBe(activeEventId);
      expect(result.checkInMethod).toBe('LOCATION');
      expect(result.pointsAwarded).toBe(15);
      expect(result.newTotalScore).toBe(initialScore + 15);

      const attendance = await prisma.eventAttendance.findUnique({
        where: {
          userId_campusEventId: {
            userId: user.id,
            campusEventId: activeEventId,
          },
        },
      });
      expect(attendance).toBeDefined();
      expect(attendance.checkInMethod).toBe('LOCATION');
      expect(attendance.pointsAwarded).toBe(15);

      const updatedUser = await prisma.user.findUniqueOrThrow({
        where: { id: user.id },
      });
      expect(updatedUser.score).toBe(initialScore + 15);
      user = updatedUser;
    });

    it('should reject check-in when user is outside radius', async () => {
      const farAwayEvent = await prisma.campusEvent.create({
        data: {
          title: 'Far Event',
          description: 'Event far away',
          locationName: 'Far Location',
          latitude: 42.5,
          longitude: -76.5,
          checkInRadius: 50,
          startTime: new Date(Date.now() - 60 * 60 * 1000),
          endTime: new Date(Date.now() + 60 * 60 * 1000),
          source: 'ADMIN_CREATED',
          approvalStatus: 'APPROVED',
          checkInMethod: 'EITHER',
          pointsForAttendance: 10,
          categories: [],
          tags: [],
        },
      });

      await expect(
        checkInService.checkInByLocation(user, {
          campusEventId: farAwayEvent.id,
          latitude: 42.4474,
          longitude: -76.4848,
        }),
      ).rejects.toThrow('User is not within check-in radius');

      await prisma.campusEvent.delete({
        where: { id: farAwayEvent.id },
      });
    });

    it('should reject duplicate check-in', async () => {
      await expect(
        checkInService.checkInByLocation(user, {
          campusEventId: activeEventId,
          latitude: 42.4474,
          longitude: -76.4848,
        }),
      ).rejects.toThrow('User has already checked in to this event');
    });

    it('should reject check-in when event has not started', async () => {
      await expect(
        checkInService.checkInByLocation(user, {
          campusEventId: futureEventId,
          latitude: 42.4474,
          longitude: -76.4848,
        }),
      ).rejects.toThrow('Event is not currently active for check-in');
    });

    it('should reject check-in when event has ended', async () => {
      await expect(
        checkInService.checkInByLocation(user, {
          campusEventId: pastEventId,
          latitude: 42.4474,
          longitude: -76.4848,
        }),
      ).rejects.toThrow('Event is not currently active for check-in');
    });

    it('should reject when campus event not found', async () => {
      await expect(
        checkInService.checkInByLocation(user, {
          campusEventId: 'non-existent-event-id',
          latitude: 42.4474,
          longitude: -76.4848,
        }),
      ).rejects.toThrow('Campus event not found');
    });
  });

  describe('checkInByQrCode', () => {
    it('should check in with valid QR code and award points', async () => {
      const initialScore = user.score;

      const result = await checkInService.checkInByQrCode(user, { qrCode });

      expect(result.attendanceId).toBeDefined();
      expect(result.campusEventId).toBe(qrEventId);
      expect(result.checkInMethod).toBe('QR_CODE');
      expect(result.pointsAwarded).toBe(20);
      expect(result.newTotalScore).toBe(initialScore + 20);

      const attendance = await prisma.eventAttendance.findUnique({
        where: {
          userId_campusEventId: {
            userId: user.id,
            campusEventId: qrEventId,
          },
        },
      });
      expect(attendance).toBeDefined();
      expect(attendance.checkInMethod).toBe('QR_CODE');
      expect(attendance.pointsAwarded).toBe(20);

      user = await prisma.user.findUniqueOrThrow({
        where: { id: user.id },
      });
    });

    it('should reject check-in with invalid QR code', async () => {
      await expect(
        checkInService.checkInByQrCode(user, {
          qrCode: 'invalid-qr-code-12345',
        }),
      ).rejects.toThrow('Invalid or unknown QR code');
    });

    it('should reject duplicate QR check-in', async () => {
      await expect(
        checkInService.checkInByQrCode(user, { qrCode }),
      ).rejects.toThrow('User has already checked in to this event');
    });
  });
});
