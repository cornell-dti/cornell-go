import { Injectable } from '@nestjs/common';
import {
  Challenge,
  EventBase,
  EventRewardType,
  EventTracker,
  User,
} from '@prisma/client';
import { EventService } from 'src/event/event.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ChallengeService {
  constructor(
    private readonly prisma: PrismaService,
    private eventService: EventService,
  ) {}

  /** Get challenges with prev challenges for a given user */
  async getChallengesByIdsWithPrevChallenge(
    user: User,
    ids: string[],
  ): Promise<Challenge[]> {
    // TODO: this can be made more efficient
    return await this.prisma.challenge.findMany({ where: { id: { in: ids } } });
  }

  /** Get a challenge by its id */
  async getChallengeById(id: string) {
    return await this.prisma.challenge.findFirstOrThrow({ where: { id } });
  }

  /** Is challenge completed by user */
  async isChallengeCompletedByUser(user: User, challenge: Challenge) {
    const num = await this.prisma.prevChallenge.count({
      where: {
        userId: user.id,
        challenge: challenge,
      },
    });

    return num > 0;
  }

  /** Find first challenge */
  async getFirstChallengeForEvent(event: EventBase) {
    return await this.prisma.challenge.findFirstOrThrow({
      where: {
        eventIndex: 0,
        linkedEvent: event,
      },
    });
  }

  /** Get next challenge in a sequence of challenges */
  async nextChallenge(chal: Challenge) {
    return (
      (await this.prisma.challenge.findFirst({
        where: {
          eventIndex: chal.eventIndex + 1,
          linkedEventId: chal.linkedEventId,
        },
      })) ?? chal
    );
  }

  /** Progress user through challenges, ensuring challengeId is current */
  async completeChallenge(
    user: User,
    challengeId: string,
  ): Promise<[EventTracker, User[]]> {
    const groupMembers = await this.prisma.user.findMany({
      where: { groupId: user.groupId },
    });

    const eventTracker: EventTracker =
      await this.eventService.getCurrentEventTrackerForUser(user);

    const curEvent = await this.prisma.eventBase.findUniqueOrThrow({
      where: { id: eventTracker.eventId },
    });

    // Ensure that the correct challenge is marked complete
    if (
      challengeId !== eventTracker.curChallengeId ||
      (groupMembers.length !== curEvent.requiredMembers &&
        curEvent.requiredMembers >= 0)
    )
      return [eventTracker, groupMembers];

    const prevChal = await this.prisma.prevChallenge.create({
      data: {
        userId: user.id,
        challengeId: eventTracker.curChallengeId,
        participants: {
          connect: groupMembers.map(m => ({ id: m.id })),
        },
        trackerId: eventTracker.id,
      },
    });

    const curChallenge = await this.prisma.challenge.findUniqueOrThrow({
      where: { id: eventTracker.curChallengeId },
    });

    const nextChallenge = await this.nextChallenge(curChallenge);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { score: { increment: 1 } },
    });

    await this.prisma.eventTracker.update({
      where: { id: eventTracker.id },
      data: {
        score: { increment: 1 },
        curChallenge: { connect: { id: nextChallenge.id } },
        completedChallenges: { connect: { id: prevChal.id } },
      },
    });

    return [eventTracker, groupMembers];
  }

  /** Check if the current event can return rewards */
  async checkForReward(eventTracker: EventTracker) {
    const eventBase = await this.prisma.eventBase.findUniqueOrThrow({
      where: { id: eventTracker.eventId },
    });

    if (
      //If user has not completed enough challenges:
      eventTracker.score < eventBase.minimumScore ||
      //If user has a reward for this event:
      (await this.prisma.eventReward.count({
        where: {
          userId: eventTracker.userId,
          eventId: eventTracker.eventId,
        },
      })) > 0 ||
      //If event has expired:
      eventBase.endTime < new Date()
    ) {
      return false;
    }

    if (eventBase.rewardType === EventRewardType.PERPETUAL) {
      const rewardTemplate = await this.prisma.eventReward.findFirst({
        where: { eventId: eventBase.id },
      });

      if (rewardTemplate !== null) {
        await this.prisma.eventReward.create({
          data: {
            ...rewardTemplate,
            userId: eventTracker.userId,
            isRedeemed: false,
            id: undefined,
          },
        });

        return true;
      }
    } else if (eventBase.rewardType === EventRewardType.LIMITED_TIME) {
      const unclaimedReward = await this.prisma.eventReward.findFirst({
        where: {
          user: null,
          event: eventBase,
        },
      });

      if (unclaimedReward !== null) {
        await this.prisma.eventReward.update({
          where: { id: unclaimedReward.id },
          data: {
            userId: eventTracker.userId,
          },
        });

        return true;
      }
    }

    return false;
  }

  async getUserCompletionDate(user: User, challenge: Challenge) {
    return (
      (
        await this.prisma.prevChallenge.findFirst({
          where: { userId: user.id, challengeId: challenge.id },
        })
      )?.timestamp.toISOString() ?? ''
    );
  }

  async setCurrentChallenge(
    user: User,
    challengeId: string,
  ): Promise<[EventBase, User[]]> {
    const group = await this.prisma.group.findUniqueOrThrow({
      where: { id: user.groupId },
      include: { curEvent: true, members: true },
    });

    const event = group.curEvent;

    const isChallengeValid = await this.eventService.isChallengeInEvent(
      challengeId,
      group.curEventId,
    );

    if (!isChallengeValid) return [event, group.members];

    const eventTracker: EventTracker =
      await this.eventService.getCurrentEventTrackerForUser(user);

    const challenge = await this.getChallengeById(challengeId);
    const curChallenge = await this.getChallengeById(
      eventTracker.curChallengeId,
    );
    const wasCompleted = await this.isChallengeCompletedByUser(user, challenge);
    const curCompleted = await this.isChallengeCompletedByUser(
      user,
      curChallenge,
    );

    // Is user skipping while it's allowed
    const isSkippingWhileAllowed =
      wasCompleted ||
      event.skippingEnabled ||
      (!wasCompleted &&
        curCompleted &&
        challenge.eventIndex === curChallenge.eventIndex + 1);

    if (!isSkippingWhileAllowed) return [event, group.members];

    await this.prisma.eventTracker.update({
      where: { id: eventTracker.id },
      data: {
        curChallengeId: challenge.id,
      },
    });

    return [event, group.members];
  }
}
