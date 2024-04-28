import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AchievementService } from './achievement.service';
import { AppModule } from '../app.module';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
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

describe('AchievementModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;
  let achievementService: AchievementService;
  let prisma: PrismaService;
  let userService: UserService;
  let eventService: EventService;
  let user: User;
  let tracker: AchievementTracker;
  let event: EventBase;
  let organizationService: OrganizationService;
  let abilityFactory: CaslAbilityFactory;
  let fullAbility: AppAbility;
  let orgUsage: OrganizationSpecialUsage;

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
        OrganizationService,
        CaslAbilityFactory,
      ],
    }).compile();

    const log = console.log;
    console.log = function () {};

    achievementService = module.get<AchievementService>(AchievementService);
    prisma = module.get<PrismaService>(PrismaService);
    userService = module.get<UserService>(UserService);
    eventService = module.get<EventService>(EventService);
    organizationService = module.get<OrganizationService>(OrganizationService);
    abilityFactory = module.get<CaslAbilityFactory>(CaslAbilityFactory);
    fullAbility = abilityFactory.createFull();

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
    it('should add an achievement: upsertAchievementFromDto', async () => {
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
      console.log(ach);

      const findAch = await prisma.achievement.findFirstOrThrow({
        where: { id: ach!.id },
      });
      expect(findAch.description).toEqual('ach dto');
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
        .imageUrl;
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
      ).imageUrl;
      console.log('after: ' + testAfterUpdate);

      expect(ach.imageUrl).toEqual('update test');
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
    await app.close();
  });
});
