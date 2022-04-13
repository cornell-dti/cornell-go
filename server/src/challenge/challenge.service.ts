import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { EventService } from 'src/event/event.service';
import { Challenge } from '../model/challenge.entity';
import { EventReward } from '../model/event-reward.entity';
import { EventBase, EventRewardType } from '../model/event-base.entity';
import { PrevChallenge } from '../model/prev-challenge.entity';
import { User } from '../model/user.entity';
import { EventTracker } from 'src/model/event-tracker.entity';
import { v4 } from 'uuid';
import { Reference } from '@mikro-orm/core';

@Injectable()
export class ChallengeService {
  constructor(
    @Inject(forwardRef(() => EventService))
    private eventService: EventService,
    @InjectRepository(Challenge)
    private challengeRepository: EntityRepository<Challenge>,
    @InjectRepository(PrevChallenge)
    private prevChallengeRepository: EntityRepository<PrevChallenge>,
    @InjectRepository(EventReward)
    private rewardRepository: EntityRepository<EventReward>,
  ) {}

  /** Get challenges with prev challenges for a given user */
  async getChallengesByIdsWithPrevChallenge(
    user: User,
    ids: string[],
  ): Promise<Challenge[]> {
    return await this.challengeRepository.find({ id: ids });
  }

  /** Get a challenge by its id */
  async getChallengeById(id: string) {
    return await this.challengeRepository.findOneOrFail({ id });
  }

  /** Is challenge completed by user */
  async isChallengeCompletedByUser(user: User, challenge: Challenge) {
    const num = await this.prevChallengeRepository.count({
      owner: user,
      challenge,
    });

    return num > 0;
  }

  /** Save a challenge entity */
  async saveChallenge(chal: Challenge) {
    await this.challengeRepository.persistAndFlush(chal);
  }

  /** Save a prev challenge entity */
  async savePrevChallenge(prevChal: PrevChallenge) {
    await this.prevChallengeRepository.persistAndFlush(prevChal);
  }

  /** Find first challenge */
  async getFirstChallengeForEvent(event: EventBase) {
    return await this.challengeRepository.findOneOrFail({
      eventIndex: 0,
      linkedEvent: event,
    });
  }

  /** Get next challenge in a sequence of challenges */
  async nextChallenge(chal: Challenge) {
    try {
      return await this.challengeRepository.findOneOrFail({
        eventIndex: chal.eventIndex + 1,
        linkedEvent: chal.linkedEvent,
      });
    } catch {
      return chal;
    }
  }

  /** Progress user through challenges, ensuring challengeId is current */
  async completeChallenge(user: User, challengeId: string) {
    const group = await user.group.load();
    const groupMembers = await group.members.loadItems();

    const eventTracker = await this.eventService.getCurrentEventTrackerForUser(
      user,
    );

    const curEvent = await eventTracker.event.load();

    // Ensure that the correct challenge is marked complete
    if (
      challengeId !== eventTracker.currentChallenge.id ||
      (groupMembers.length !== curEvent.requiredMembers &&
        curEvent.requiredMembers >= 0)
    )
      return eventTracker;

    const prevChal = this.prevChallengeRepository.create({
      owner: user,
      challenge: eventTracker.currentChallenge,
      completionPlayers: groupMembers,
      foundTimestamp: new Date(),
    });

    await this.prevChallengeRepository.persistAndFlush(prevChal);

    user.score += 1;
    eventTracker.eventScore += 1;

    const nextChallenge = await this.nextChallenge(
      await eventTracker.currentChallenge.load(),
    );

    eventTracker.currentChallenge.set(nextChallenge);
    eventTracker.completed.add(prevChal);

    await this.eventService.saveTracker(eventTracker);

    return eventTracker;
  }

  /** Check if the current event can return rewards */
  async checkForReward(eventTracker: EventTracker) {
    const eventBase = await eventTracker.event.load();
    //If User has not completed the event/done all the challenges then:
    if (
      (await eventTracker.completed.loadCount()) !==
      (await eventBase.challenges.loadCount())
    ) {
      return null;
    }

    const rewardType = eventBase.rewardType;
    if (
      rewardType === EventRewardType.LIMITED_TIME_EVENT &&
      eventBase.time > new Date()
    ) {
      return null;
    }

    if (rewardType === EventRewardType.PERPETUAL) {
      const newReward = await this.rewardRepository.findOne({
        containingEvent: eventBase,
      });
      if (newReward !== null) {
        newReward.claimingUser = Reference.create(eventTracker.user);
        newReward.isRedeemed = false;
        const reward = this.rewardRepository.create({ ...newReward, id: v4() });
        await this.rewardRepository.persistAndFlush(reward);
        return newReward;
      }
      return null;
    }

    const unclaimedReward = await this.rewardRepository.findOne({
      claimingUser: null,
      containingEvent: eventBase,
    });
    if (unclaimedReward !== null) {
      unclaimedReward.claimingUser = Reference.create(eventTracker.user);
      return unclaimedReward;
    }
    return null;
  }
}
