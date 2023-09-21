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
import { RewardDto } from '../reward/reward.dto';
import { RewardService } from '../reward/reward.service';
import { ChallengeDto } from './challenge.dto';

describe('ChallengeModule E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;
  let challengeService: ChallengeService;
  let prisma: PrismaService;
  let userService: UserService;
  let eventService: EventService;
  let rewardService: RewardService;
  let user: User;
  let tracker: EventTracker;
  let event: EventBase;
  let organizationService: OrganizationService;

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
        RewardService,
      ],
    }).compile();

    const log = console.log;
    console.log = function () {};

    challengeService = module.get<ChallengeService>(ChallengeService);
    prisma = module.get<PrismaService>(PrismaService);
    userService = module.get<UserService>(UserService);
    eventService = module.get<EventService>(EventService);
    rewardService = module.get<RewardService>(RewardService);
    organizationService = module.get<OrganizationService>(OrganizationService);

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

    console.log = log;
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
      expect(score + 1).toEqual(score2);
      expect(
        await challengeService.isChallengeCompletedByUser(user, chal),
      ).toEqual(true);
    });
  });

  describe('checkForReward', () => {
    it('return reward after completion', async () => {
      const user = await userService.register(
        'test@gmail.com',
        'test',
        '2025',
        0,
        0,
        AuthType.GOOGLE,
        'asdf',
        'GRADUATE',
      );
      const tracker = await eventService.getCurrentEventTrackerForUser(user);

      const reward = await challengeService.checkForReward(tracker);
      expect(reward).toEqual(null);

      const chal = await prisma.challenge.findFirstOrThrow({
        where: { id: tracker.curChallengeId },
      });
      await challengeService.completeChallenge(user, chal.id);

      const tracker2 = await prisma.eventTracker.findFirstOrThrow({
        where: {
          id: tracker.id,
        },
      });

      //create new reward for default event
      const findreward = await prisma.eventReward.findFirst({
        where: { eventId: tracker.eventId },
      });
      if (findreward == null) {
        const rewardTemplate: RewardDto = {
          id: 'abc1',
          eventId: tracker.eventId,
          description: 'test reward',
          redeemInfo: 'ask nikita he will give u a bajillion v bucks',
          isRedeemed: false,
          isAchievement: true,
          points: 100,
        };

        await rewardService.upsertRewardFromDto(rewardTemplate);
      }
      const reward3 = await challengeService.checkForReward(tracker2);
      expect(reward3?.userId).toEqual(tracker2.userId);
    });
  });

  describe('CR', () => {
    it('should add a challenge to eventbase: upsertChallengeFromDto', async () => {
      const chaldto: ChallengeDto = {
        id: '12345',
        name: 'test',
        description: 'chal dto',
        imageUrl: 'url',
        lat: 70,
        long: 70,
        awardingRadius: 1,
        closeRadius: 2,
        containingEventId: event.id,
      };
      const chal = await challengeService.upsertChallengeFromDto(chaldto);
      const findChal = await prisma.challenge.findFirstOrThrow({
        where: { id: chal.id },
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

      const chalsByUser = await challengeService.getChallengesByIdsForUser(
        user,
        false,
        [chal.id],
      );
      expect(chalsByUser[0]).toEqual(chal);
      const chalById = await challengeService.getChallengeById(chal.id);
      expect(chalById).toEqual(chal);

      const secondChalDTO: ChallengeDto = {
        id: '123',
        name: 'test',
        description: 'chal dto',
        imageUrl: 'update test',
        lat: 70,
        long: 70,
        awardingRadius: 1,
        closeRadius: 2,
        containingEventId: event.id,
      };

      const newChal = await challengeService.upsertChallengeFromDto(
        secondChalDTO,
      );
      // console.log(newChal.eventIndex);
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

  describe('UD', () => {
    it('should update challenge from eventbase: upsertChallengeFromDto', async () => {
      const chalID = (await prisma.challenge.findFirstOrThrow()).id;
      const chaldto: ChallengeDto = {
        id: chalID,
        name: 'test',
        description: 'chal dto',
        imageUrl: 'update test',
        lat: 70,
        long: 70,
        awardingRadius: 1,
        closeRadius: 2,
        containingEventId: event.id,
      };
      await challengeService.upsertChallengeFromDto(chaldto);
      const chal = await prisma.challenge.findFirstOrThrow({
        where: { id: chalID },
      });
      expect(chal.imageUrl).toEqual('update test');
    });
  });

  describe('Delete', () => {
    it('should remove challenge from eventbase: removeChallenge', async () => {
      const chal = await prisma.challenge.findFirstOrThrow({
        where: { linkedEventId: event.id, defaultOf: null },
      });

      const orgID = (
        await prisma.eventBase.findFirstOrThrow({
          where: { id: event.id },
          include: { usedIn: true },
        })
      ).usedIn[0].id;
      // console.log(orgID);

      await prisma.organization.update({
        where: { id: orgID },
        data: { managers: { connect: { id: user.id } } },
      });

      await prisma.user.update({
        where: { id: user.id },
        data: { managerOf: { connect: { id: orgID } } },
      });

      // const manager = await prisma.user.findFirstOrThrow({
      //   where: { id: user.id },
      //   include: { managerOf: true },
      // });

      // console.log(manager.managerOf);

      // const managers = (
      //   await prisma.organization.findFirstOrThrow({
      //     where: { id: orgID },
      //     include: { managers: true },
      //   })
      // ).managers;

      // console.log(managers.find(o => o.id === user.id));

      // const c = (
      //   await prisma.challenge.findFirstOrThrow({
      //     where: { id: chal.id },
      //   })
      // ).linkedEventId;

      // const e = await prisma.eventBase.findFirstOrThrow({
      //   where: { id: c! },
      //   include: { usedIn: true },
      // });

      // const m = await prisma.organization.findFirstOrThrow({
      //   where: { id: e.usedIn[0].id },
      //   include: { managers: true },
      // });

      // console.log(orgID);
      // console.log(m.id);
      // console.log(m.managers.find(o => o.id === user.id));

      const removed = await challengeService.removeChallenge(chal.id, user);
      // console.log('del:', removed);
      const chalres = await prisma.challenge.findFirst({
        where: { id: chal.id },
      });

      expect(chalres).toEqual(null);
    });
  });

  describe('setCurrentChallenge', () => {
    it('should set challenge to current', async () => {
      const secondChal = await prisma.challenge.findFirstOrThrow({
        where: {
          eventIndex: 1,
          linkedEvent: event,
        },
      });
      await challengeService.setCurrentChallenge(user, secondChal.id);
      const tracker = await eventService.getCurrentEventTrackerForUser(user);
      expect(tracker.curChallengeId).toEqual(secondChal.id);
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
