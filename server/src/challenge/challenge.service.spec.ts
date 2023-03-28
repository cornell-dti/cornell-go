import { Test, TestingModule } from '@nestjs/testing';
import { ChallengeService } from './challenge.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { AuthType, User, EventBase, EventTracker } from '@prisma/client';
import { SessionLogService } from '../session-log/session-log.service';
import { EventService } from '../event/event.service';
import { ClientService } from '../client/client.service';
import { GroupService } from '../group/group.service';
import { OrganizationService } from '../organization/organization.service';
import { ClientModule } from '../client/client.module';
import { RewardDto } from '../reward/reward.dto';
import { RewardService } from '../reward/reward.service';
import { ChallengeDto } from './challenge.dto';

describe('ChallengeService', () => {
  let challengeService: ChallengeService;
  let prisma: PrismaService;
  let userService: UserService;
  let eventService: EventService;
  let rewardService: RewardService;
  let user: User;
  let tracker: EventTracker;
  let event: EventBase;

  beforeEach(async () => {
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

    user = await userService.register(
      'test@gmail.com',
      'test',
      'CS',
      '2025',
      0,
      0,
      AuthType.GOOGLE,
      'asdf',
    );
    tracker = await eventService.getCurrentEventTrackerForUser(user);
    event = await prisma.eventBase.findUniqueOrThrow({
      where: { id: tracker.eventId },
    });

    console.log = log;
  });

  it('should be defined', () => {
    expect(challengeService).toBeDefined();
  });

  describe('completeChallenge', () => {
    it('should complete the challenge', async () => {
      const score = user.score;
      const trackerScore = tracker.score;

      const chalId = (
        await prisma.challenge.findFirstOrThrow({
          where: { id: tracker.curChallengeId },
        })
      ).id;
      await challengeService.completeChallenge(user, chalId);
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
    });
  });

  describe('checkForReward', () => {
    beforeEach(async () => {});

    it('return reward after completion and return true for isChallengeCompletedByUser', async () => {
      const user = await userService.register(
        'test@gmail.com',
        'test',
        'CS',
        '2025',
        0,
        0,
        AuthType.GOOGLE,
        'asdf',
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

  describe('CRUD', () => {
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
    it('should read challenges from eventbase: getFirstChallengeForEvent, getChallengesByIdsForUser, getChallengeById, nextChallenge ', async () => {
      const firstChal = await prisma.challenge.findFirstOrThrow({
        where: {
          eventIndex: 0,
          linkedEvent: event,
        },
      });
      const first = await challengeService.getFirstChallengeForEvent(event);
      expect(first).toEqual(firstChal);
      const chal = await prisma.challenge.findFirstOrThrow();
      const chalsByUser = await challengeService.getChallengesByIdsForUser(
        user,
        false,
        [chal.id],
      );
      expect(chalsByUser[0]).toEqual(chal);
      const chalById = await challengeService.getChallengeById(chal.id);
      expect(chalById).toEqual(chal);
      const nextChal = await challengeService.nextChallenge(
        await prisma.challenge.findFirstOrThrow({
          where: { linkedEventId: event.id, eventIndex: 0 },
        }),
      );
      expect(nextChal.eventIndex).toEqual(1);
    });
    it('should remove challenge from eventbase: removeChallenge', async () => {
      const chalID = (
        await prisma.challenge.findFirstOrThrow({
          where: { imageUrl: 'url' },
        })
      ).id;

      await challengeService.removeChallenge(chalID, user);
      const chalID2 = (
        await prisma.challenge.findFirstOrThrow({
          where: { imageUrl: 'url' },
        })
      ).id;
    });
  });

  afterAll(async () => {
    await prisma.user.delete({
      where: {
        id: user.id,
      },
    });
  });
});
