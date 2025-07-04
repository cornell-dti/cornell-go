import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AchievementService } from './achievement.service';
import { AppModule } from '../app.module';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { ChallengeService } from '../challenge/challenge.service';

import {
  AuthType,
  User,
  EventBase,
  EventTracker,
  AchievementTracker,
  Achievement,
  OrganizationSpecialUsage,
} from '@prisma/client';
import { SessionLogService } from '../session-log/session-log.service';
import { EventService } from '../event/event.service';
import { ClientService } from '../client/client.service';
import { GroupService } from '../group/group.service';
import { OrganizationService } from '../organization/organization.service';
import { ClientModule } from '../client/client.module';
import { AchievementDto, AchievementTrackerDto } from './achievement.dto';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { ChallengeDto, ChallengeLocationDto } from '../challenge/challenge.dto';
import { AchievementTypeDto } from './achievement.dto';
import { GroupGateway } from '../group/group.gateway';

describe('AchievementModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;
  let achievementService: AchievementService;
  let prisma: PrismaService;
  let userService: UserService;
  let eventService: EventService;
  let user: User;
  let tracker: AchievementTracker;
  let exJourney: EventBase;
  let exJourney1: EventBase;
  let exJourney2: EventBase;
  let exChallenge1: EventBase;
  let exChallenge2: EventBase;
  let organizationService: OrganizationService;
  let abilityFactory: CaslAbilityFactory;
  let fullAbility: AppAbility;
  let orgUsage: OrganizationSpecialUsage;
  let challengeService: ChallengeService;
  let groupGateway: GroupGateway;

  /** beforeAll runs before anything else. It adds new users and prerequisites.
   * afterAll runs after all the tests. It removes lingering values in the database.
   */
  beforeAll(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
    const module: TestingModule = await Test.createTestingModule({
      imports: [ClientModule],
      providers: [
        AchievementService,
        PrismaService,
        UserService,
        SessionLogService,
        EventService,
        ClientService,
        GroupService,
        ChallengeService,
        OrganizationService,
        CaslAbilityFactory,
      ],
    }).compile();

    const log = console.log;
    console.log = function () {};

    achievementService = module.get<AchievementService>(AchievementService);
    challengeService = module.get<ChallengeService>(ChallengeService);
    prisma = module.get<PrismaService>(PrismaService);
    userService = module.get<UserService>(UserService);
    eventService = module.get<EventService>(EventService);
    organizationService = module.get<OrganizationService>(OrganizationService);
    abilityFactory = module.get<CaslAbilityFactory>(CaslAbilityFactory);
    fullAbility = abilityFactory.createFull();
    groupGateway = moduleRef.get<GroupGateway>(GroupGateway);

    user = await userService.register(
      'test@gmail.com',
      'test',
      '2025',
      'Engineering',
      'Computer Science',
      ['Nature'],
      0,
      0,
      AuthType.DEVICE,
      'asdf',
      'GRADUATE',
    );

    user = await prisma.user.findFirstOrThrow({
      where: { id: user.id },
      include: { memberOf: true },
    });
    console.log = log;
  });

  it('should successfully find AchievementService', async () => {
    const achService = moduleRef.get<AchievementService>(AchievementService);
    expect(achService).toBeDefined();
  });

  describe('Create and read functions', () => {
    it('should add an achievement: upsertAchievementFromDto; should create a tracker with progress 0', async () => {
      const orgUsage = OrganizationSpecialUsage;
      const orgId = (
        await organizationService.getDefaultOrganization(orgUsage.DEVICE_LOGIN)
      ).id;

      const achDto: AchievementDto = {
        id: '12345',
        eventId: 'event123',
        name: 'test',
        description: 'ach dto',
        requiredPoints: 1,
        imageUrl: 'url',
        locationType: ChallengeLocationDto.ENG_QUAD,
        achievementType: AchievementTypeDto.TOTAL_CHALLENGES_OR_JOURNEYS,
        initialOrganizationId: orgId,
      };

      const ach = await achievementService.upsertAchievementFromDto(
        fullAbility,
        achDto,
      );

      const findAch = await prisma.achievement.findFirstOrThrow({
        where: { id: ach!.id },
      });

      if (ach) {
        tracker = await achievementService.createAchievementTracker(
          user,
          ach.id,
        );
        console.log(tracker);
      }

      expect(findAch.description).toEqual('ach dto');
      expect(tracker.progress).toEqual(0);
      expect(tracker.dateComplete).toEqual(null);
    });

    it('should read achievements: getAchievementFromId, getAchievementsByIdsForAbility', async () => {
      const ach = await prisma.achievement.findFirstOrThrow({
        where: {
          description: 'ach dto',
        },
      });
      const first = await achievementService.getAchievementFromId(ach.id);
      expect(first).toEqual(ach);

      const achsByUser =
        await achievementService.getAchievementsByIdsForAbility(fullAbility, [
          ach.id,
        ]);
      expect(achsByUser[0]).toEqual(ach);
    });
  });

  describe('Update functions', () => {
    it('should update an achievement: upsertAchievementFromDto', async () => {
      const achId = (await prisma.achievement.findFirstOrThrow()).id;
      const test = (await achievementService.getAchievementFromId(achId))
        ?.imageUrl;
      console.log('before: ' + test);
      const orgUsage = OrganizationSpecialUsage;
      const orgId = (
        await organizationService.getDefaultOrganization(orgUsage.DEVICE_LOGIN)
      ).id;

      const achDto: AchievementDto = {
        id: achId,
        eventId: 'event123',
        name: 'test',
        description: 'ach dto',
        requiredPoints: 1,
        imageUrl: 'update test',
        locationType: ChallengeLocationDto.ENG_QUAD,
        achievementType: AchievementTypeDto.TOTAL_CHALLENGES_OR_JOURNEYS,
        initialOrganizationId: orgId,
      };

      await achievementService.upsertAchievementFromDto(fullAbility, achDto);
      const ach = await prisma.achievement.findFirstOrThrow({
        where: { id: achId },
      });
      const testAfterUpdate = (
        await achievementService.getAchievementFromId(achId)
      )?.imageUrl;
      console.log('after: ' + testAfterUpdate);

      expect(ach.imageUrl).toEqual('update test');
    });
  });

  describe('Testing achievement tracker', () => {
    it('should test ach tracker on dif achievement types; update tracker with progress; and mark tracker as complete when achievement criteria are met', async () => {
      const orgUsage = OrganizationSpecialUsage;
      const orgId = (
        await organizationService.getDefaultOrganization(orgUsage.DEVICE_LOGIN)
      ).id;

      exJourney1 = await organizationService.makeDefaultEvent(orgId);
      exJourney2 = await organizationService.makeDefaultEvent(orgId);
      exChallenge1 = await organizationService.makeDefaultEvent(orgId);
      exChallenge2 = await organizationService.makeDefaultEvent(orgId);
      const achChalJourDto: AchievementDto = {
        id: '',
        eventId: exJourney1.id,
        name: 'achChalJourDto',
        description: 'ach dto',
        requiredPoints: 1,
        imageUrl: 'update test',
        locationType: ChallengeLocationDto.ARTS_QUAD,
        achievementType: AchievementTypeDto.TOTAL_CHALLENGES_OR_JOURNEYS,
        initialOrganizationId: orgId,
      };
      const achChalDto: AchievementDto = {
        id: '',
        eventId: exChallenge1.id,
        name: 'achChalDto',
        description: 'ach dto',
        requiredPoints: 1,
        imageUrl: 'update test',
        locationType: ChallengeLocationDto.ARTS_QUAD,
        achievementType: AchievementTypeDto.TOTAL_CHALLENGES,
        initialOrganizationId: orgId,
      };

      const achPtsDto: AchievementDto = {
        id: '',
        eventId: exChallenge2.id,
        name: 'achPtsDto',
        description: 'ach dto',
        requiredPoints: 10,
        imageUrl: 'update test',
        locationType: ChallengeLocationDto.ARTS_QUAD,
        achievementType: AchievementTypeDto.TOTAL_POINTS,
        initialOrganizationId: orgId,
      };

      const achJourDto: AchievementDto = {
        id: '',
        eventId: exJourney2.id,
        name: 'achJourDto',
        description: 'ach dto',
        requiredPoints: 1,
        imageUrl: 'update test',
        locationType: ChallengeLocationDto.ARTS_QUAD,
        achievementType: AchievementTypeDto.TOTAL_JOURNEYS,
        initialOrganizationId: orgId,
      };

      await achievementService.upsertAchievementFromDto(
        fullAbility,
        achChalDto,
      );
      await achievementService.upsertAchievementFromDto(
        fullAbility,
        achChalJourDto,
      );
      await achievementService.upsertAchievementFromDto(
        fullAbility,
        achJourDto,
      );
      await achievementService.upsertAchievementFromDto(fullAbility, achPtsDto);

      const achChal = await prisma.achievement.findFirstOrThrow({
        where: { name: 'achChalDto' },
      });
      const achChalJour = await prisma.achievement.findFirstOrThrow({
        where: { name: 'achChalJourDto' },
      });
      const achJour = await prisma.achievement.findFirstOrThrow({
        where: { name: 'achJourDto' },
      });
      const achPts = await prisma.achievement.findFirstOrThrow({
        where: { name: 'achPtsDto' },
      });

      const trackerChal = await achievementService.createAchievementTracker(
        user,
        achChal.id,
      );
      const trackerChalJour = await achievementService.createAchievementTracker(
        user,
        achChalJour.id,
      );
      const trackerJour = await achievementService.createAchievementTracker(
        user,
        achJour.id,
      );
      const trackerPts = await achievementService.createAchievementTracker(
        user,
        achPts.id,
      );

      await groupGateway.setCurrentEvent(user, { eventId: exChallenge1.id });
      await challengeService.completeChallenge(user);

      const newTrackerChal = await prisma.achievementTracker.findFirstOrThrow({
        where: { id: trackerChal.id },
      });

      expect(newTrackerChal.progress).toBeGreaterThan(0);
      expect(newTrackerChal.dateComplete).not.toBeNull();

      expect(trackerChalJour.progress).toBe(0);
      expect(trackerJour.progress).toBe(0);
      expect(trackerPts.progress).toBe(0);

      await groupGateway.setCurrentEvent(user, { eventId: exJourney1.id });
      await challengeService.completeChallenge(user);

      const newTrackerChalJour =
        await prisma.achievementTracker.findFirstOrThrow({
          where: { id: trackerChalJour.id },
        });
      expect(newTrackerChalJour.progress).toBeGreaterThan(0);
      expect(newTrackerChalJour.dateComplete).not.toBeNull();
    });
  });

  describe('Delete functions', () => {
    it('should remove achievement: removeAchievement', async () => {
      const ach = await prisma.achievement.findFirstOrThrow({
        where: { description: 'ach dto' },
      });

      await achievementService.removeAchievement(fullAbility, ach.id);
      const achres = await prisma.challenge.findFirst({
        where: { id: ach.id },
      });
      expect(achres).toEqual(null);
    });
  });

  afterAll(async () => {
    await prisma.user.delete({
      where: {
        id: user.id,
      },
    });
    await prisma.achievementTracker.deleteMany({});
    await prisma.achievement.deleteMany({});
    await app.close();
  });
});
