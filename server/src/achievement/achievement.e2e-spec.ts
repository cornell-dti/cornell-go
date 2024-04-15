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
} from '@prisma/client';
import { SessionLogService } from '../session-log/session-log.service';
import { EventService } from '../event/event.service';
import { ClientService } from '../client/client.service';
import { GroupService } from '../group/group.service';
import { OrganizationService } from '../organization/organization.service';
import { ClientModule } from '../client/client.module';
import { AchievementDto, AchievementTrackerDto } from './achievement.dto';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';



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
    
    user = await userService.register(
      'test@gmail.com',
      'test',
      '2025',
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

  describe('Update functions', () => {
    it('should update an achievement: upsertAchievementFromDto', async () => {
      const achID = (await prisma.achievement.findFirstOrThrow()).id;
      const achDTO: AchievementDto = {
        id: achID,
        name: 'test achievement',
        description: 'chal dto',
        requiredPoints: 50,
        imageUrl: 'update test',
      };
      await achievementService.upsertAchievementFromDto(fullAbility, achDTO);
      const ach = await prisma.achievement.findFirstOrThrow({
        where: { id: achID },
      });
      expect(ach.imageUrl).toEqual('update test'); 
  });

  describe('Delete functions', () => {
    it('should remove achievement from eventbase: removeAchievement', async () => {
      const ach = await prisma.achievement.findFirstOrThrow();

      await achievementService.removeAchievement(fullAbility, ach.id);
      const achres = await prisma.challenge.findFirst({
        where: { id: ach.id },
      });
      expect(achres).toEqual(null);
    });
  });



};