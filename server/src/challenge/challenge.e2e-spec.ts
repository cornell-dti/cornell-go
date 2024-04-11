import * as request from 'supertest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { ChallengeService } from './challenge.service';
import { AppModule } from '../app.module';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import {
  AuthType,
  User,
  EventBase,
  EventTracker,
  Challenge,
} from '@prisma/client';
import { SessionLogService } from '../session-log/session-log.service';
import { EventService } from '../event/event.service';
import { ClientService } from '../client/client.service';
import { GroupService } from '../group/group.service';
import { OrganizationService } from '../organization/organization.service';
import { ClientModule } from '../client/client.module';
import { ChallengeDto } from './challenge.dto';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';

describe('ChallengeModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;
  let challengeService: ChallengeService;
  let prisma: PrismaService;
  let userService: UserService;
  let eventService: EventService;
  let user: User;
  let tracker: EventTracker;
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
        ChallengeService,
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

    challengeService = module.get<ChallengeService>(ChallengeService);
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

    tracker = await eventService.getCurrentEventTrackerForUser(user);

    event = await prisma.eventBase.findUniqueOrThrow({
      where: { id: tracker.eventId },
    });
  });

  it('should successfully find ChallengeService', async () => {
    const chService = moduleRef.get<ChallengeService>(ChallengeService);
    expect(chService).toBeDefined();
  });

  describe('completeChallenge', () => {
    it('should complete the challenge', async () => {
      const score = user.score;
      const trackerScore = tracker.score;

      let chal = await prisma.challenge.findFirstOrThrow({
        where: { id: tracker.curChallengeId },
      });

      await challengeService.completeChallenge(user, chal.id);

      const score2 = (
        await prisma.user.findFirstOrThrow({
          where: {
            id: user.id,
          },
        })
      ).score;

      const trackerScore2 = (
        await prisma.eventTracker.findFirstOrThrow({
          where: {
            id: tracker.id,
          },
        })
      ).score;

      expect(score + chal.points).toEqual(score2);
      expect(trackerScore + chal.points).toEqual(trackerScore2);
      expect(
        await challengeService.isChallengeCompletedByUser(user, chal),
      ).toEqual(true);
    });
  });

  describe('Create and read functions', () => {
    it('should add a challenge to eventbase: upsertChallengeFromDto', async () => {
      const chalDto: ChallengeDto = {
        id: '12345',
        name: 'test',
        location: 'ENG_QUAD',
        description: 'chal dto',
        points: 1,
        imageUrl: 'url',
        latF: 70,
        longF: 70,
        awardingRadiusF: 1,
        closeRadiusF: 2,
        linkedEventId: event.id,
      };

      const chal = await challengeService.upsertChallengeFromDto(
        fullAbility,
        chalDto,
      );

      const findChal = await prisma.challenge.findFirstOrThrow({
        where: { id: chal!.id },
      });
      expect(findChal.description).toEqual('chal dto');
    });

    it('should read challenges from eventbase: getFirstChallengeForEvent, getChallengesByIdsForUser, getChallengeById, nextChallenge ', async () => {
      const firstChal = await prisma.challenge.findFirstOrThrow({
        where: {
          eventIndex: 0,
          linkedEvent: event,
        },
      });
      const first = await challengeService.getFirstChallengeForEvent(event);
      expect(first).toEqual(firstChal);
      const chal = await prisma.challenge.findFirstOrThrow({
        where: { linkedEventId: event.id },
      });

      const chalsByUser = await challengeService.getChallengesByIdsForAbility(
        fullAbility,
        [chal.id],
      );
      expect(chalsByUser[0]).toEqual(chal);
      const chalById = await challengeService.getChallengeById(chal.id);
      expect(chalById).toEqual(chal);

      const secondChalDto: ChallengeDto = {
        id: '123',
        name: 'test',
        location: 'ANY',
        description: 'chal dto',
        points: 1,
        imageUrl: 'update test',
        latF: 70,
        longF: 70,
        awardingRadiusF: 1,
        closeRadiusF: 2,
        linkedEventId: event.id,
      };

      await challengeService.upsertChallengeFromDto(fullAbility, secondChalDto);
      const nextChal = await challengeService.nextChallenge(
        await prisma.challenge.findFirstOrThrow({
          where: { linkedEventId: event.id, eventIndex: 0 },
        }),
      );
      expect(nextChal.eventIndex).toEqual(1);
      const evchal = await challengeService.getFirstChallengeForEvent(event);
      expect(evchal.eventIndex).toEqual(0);
    });
  });

  describe('Update functions', () => {
    it('should update challenge from eventbase: upsertChallengeFromDto', async () => {
      const chalID = (await prisma.challenge.findFirstOrThrow()).id;
      const chalDto: ChallengeDto = {
        id: chalID,
        name: 'test',
        location: 'ENG_QUAD',
        description: 'chal dto',
        points: 1,
        imageUrl: 'update test',
        latF: 70,
        longF: 70,
        awardingRadiusF: 1,
        closeRadiusF: 2,
        linkedEventId: event.id,
      };
      await challengeService.upsertChallengeFromDto(fullAbility, chalDto);
      const chal = await prisma.challenge.findFirstOrThrow({
        where: { id: chalID },
      });
      expect(chal.imageUrl).toEqual('update test');
    });
  });

  describe('Delete functions', () => {
    it('should remove challenge from eventbase: removeChallenge', async () => {
      const chal = await prisma.challenge.findFirstOrThrow({
        where: { linkedEventId: event.id },
      });

      const orgID = (
        await prisma.eventBase.findFirstOrThrow({
          where: { id: event.id },
          include: { usedIn: true },
        })
      ).usedIn[0].id;

      await prisma.organization.update({
        where: { id: orgID },
        data: { managers: { connect: { id: user.id } } },
      });

      await prisma.user.update({
        where: { id: user.id },
        data: { managerOf: { connect: { id: orgID } } },
      });

      /*await challengeService.removeChallenge(fullAbility, chal.id);
      const chalres = await prisma.challenge.findFirst({
        where: { id: chal.id },
      });

      expect(chalres).toEqual(null);*/
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
