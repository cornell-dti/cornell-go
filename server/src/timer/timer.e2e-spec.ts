import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../app.module';
import { PrismaService } from '../prisma/prisma.service';
import { TimerService } from './timer.service';
import { AuthType, EnrollmentType } from '@prisma/client';

describe('TimerModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;
  let prisma: PrismaService;
  let eventId: string;
  let groupId: string;

  beforeAll(async () => {
    // Setup: Create test environment
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],  // Loads entire app with real services
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();

    // Get the services you need for testing
    prisma = moduleRef.get<PrismaService>(PrismaService);

    const event = await prisma.eventBase.create({
        data: {
            requiredMembers: 1,
            name: 'e2e',
            description: 'e2e',
            timeLimitation: 'PERPETUAL',
            indexable: true,
            endTime: new Date(Date.now() + 3600_000),
            latitude: 0,
            longitude: 0,
            difficulty: 'EASY',
            category: 'FOOD',
        },
    });
    eventId = event.id;


    //create a test group
    const group = await prisma.group.create({
      data: {
        friendlyId: 'grp-e2e',
        curEvent: { connect: { id: event.id } },
      },
    });
    groupId = group.id;
    
    //create a test user
    const user = await prisma.user.create({
        data: {
            id: '456',
            email: 'player1@cornell.edu',
            username: 'player1',
            year:'2024',
            college: 'Engineering',
            major: 'Computer Science',
            interests: ['Nature'],
            score: 100,
            enrollmentType: EnrollmentType.UNDERGRADUATE,
            authType: AuthType.DEVICE,
            authToken: 'player1auth',
            group: { connect: { id: group.id } },
            hashedRefreshToken: 'hashed_refresh_token_placeholder',
            administrator: false,
        },
    });

    //create a test challenge
    const challenge = await prisma.challenge.create({
        data: {
            id: '123',
            eventIndex: 0,
            location: 'ANY',
            name: 'Test Challenge',
            description: 'This is a test challenge',
            points: 100,
            timerLength: 3600,
            imageUrl: 'https://example.com/image.jpg',
            latitude: 0,
            longitude: 0,
            awardingRadius: 100,
            closeRadius: 100,
        },
    });

  });

  beforeEach(async () => {
    await prisma.challengeTimer.deleteMany({ where: { userId: '456', challengeId: '123' } });
  });

  it('should create and successfully find TimerService', async () => {
    const timerService = moduleRef.get<TimerService>(TimerService);
    expect(timerService).toBeDefined();
  });

  it('should create and successfuly start a timer', async () => {
    const timerService = moduleRef.get<TimerService>(TimerService);
    const timer = await timerService.startTimer('123', '456');
    expect(timer).toBeDefined();
    expect(timer.timerId).toBeDefined();
    expect(timer.endTime).toBeDefined();
    expect(timer.challengeId).toBeDefined();
  });

  it('should create and successfuly extend a timer', async () => {
    const timerService = moduleRef.get<TimerService>(TimerService);
    const timer = await timerService.startTimer('123', '456');
    const oldEndTime = new Date(timer.endTime).getTime();

    const extendedTimer = await timerService.extendTimer('123', '456');
    expect(extendedTimer).toBeDefined();
    expect(extendedTimer.timerId).toBeDefined();
    expect(extendedTimer.challengeId).toBeDefined();
    expect(extendedTimer.newEndTime).toBeDefined();
    expect(new Date(extendedTimer.newEndTime).getTime()).toBeGreaterThan(oldEndTime);
  });

  it('should properly complete a timer', async () => {
    const timerService = moduleRef.get<TimerService>(TimerService);
    const timer = await timerService.startTimer('123', '456');

    const completedTimer = await timerService.completeTimer('123', '456');
    expect(completedTimer).toBeDefined();
    expect(completedTimer.timerId).toBeDefined();
    expect(completedTimer.challengeId).toBeDefined();
    expect(completedTimer.challengeCompleted).toBeTruthy();
  });

  it('should properly send a warning', async () => {
    const timerService = moduleRef.get<TimerService>(TimerService);
    await timerService.startTimer('123', '456');

    const before = await prisma.challengeTimer.findFirst({
      where: { challengeId: '123', userId: '456' },
    });
    if (!before) {
      throw new Error('Timer not found');
    }

    const warning = await timerService.sendWarning('123', '456', 300);
    expect(warning).toBeDefined();
    expect(warning.challengeId).toBe('123');
    expect(warning.milestone).toBe(300);
    expect(warning.timeRemaining).toBeGreaterThan(0);

    const after = await prisma.challengeTimer.findFirst({
      where: { challengeId: '123', userId: '456' },
    });
    expect(after).toBeDefined();
    expect(after!.warningMilestonesSent).toContain(300);
    expect(after!.warningMilestonesSent.length).toBeGreaterThan(before!.warningMilestonesSent.length);
    expect(after!.lastWarningSent).toBeInstanceOf(Date);
    expect(after!.lastWarningSent!.getTime()).toBeGreaterThan(0);
  });

  afterAll(async () => {
    // Cleanup: Close connections and delete test data
    await prisma.challengeTimer.deleteMany({ where: { userId: '456', challengeId: '123' } });
    await prisma.challenge.delete({where: {id: '123'}});
    await prisma.user.delete({where: {id: '456'}});
    await prisma.group.delete({where: {id: groupId}});
    await prisma.eventBase.delete({where: {id: eventId}});
    await app.close();
  });
});