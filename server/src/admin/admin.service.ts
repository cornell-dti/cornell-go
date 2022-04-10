import { ChallengeDto } from './update-challenges.dto';
import { EventRewardType } from './../model/event-base.entity';
import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { ConsoleLogger, Injectable } from '@nestjs/common';
import { Challenge } from 'src/model/challenge.entity';
import { EventBase } from 'src/model/event-base.entity';
import { EventReward } from 'src/model/event-reward.entity';
import { RewardDto } from './update-rewards.dto';
import { User } from 'src/model/user.entity';
import { EventDto } from './update-events.dto';
import { v4 } from 'uuid';
import e from 'express';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User) private userRepository: EntityRepository<User>,
    @InjectRepository(EventReward)
    private rewardRepository: EntityRepository<EventReward>,
    @InjectRepository(EventBase)
    private eventRepository: EntityRepository<EventBase>,
    @InjectRepository(Challenge)
    private challengeRepository: EntityRepository<Challenge>,
  ) {}

  async requestAdminAccess(adminId: string) {
    const admin = await this.userRepository.findOne({ id: adminId });
    if (admin) {
      admin.adminRequested = true;
      await this.userRepository.persistAndFlush(admin);
    }
  }

  async setAdminStatus(adminId: string, granted: boolean) {
    const admin = await this.userRepository.findOne({ id: adminId });
    if (admin) {
      admin.adminGranted = granted;
      admin.adminRequested = false;
      await this.userRepository.persistAndFlush(admin);
    }
    return admin;
  }

  async getAllRequestingAdmins() {
    return await this.userRepository.find({
      adminRequested: true,
    });
  }

  async getAllEventData() {
    return await this.eventRepository.find({});
  }

  async getAllChallengeData() {
    return await this.challengeRepository.find({});
  }

  async getEventById(eventId: string) {
    return await this.eventRepository.findOneOrFail({ id: eventId });
  }

  async getChallengeById(challengeId: string) {
    return await this.challengeRepository.findOneOrFail({ id: challengeId });
  }

  async removeEvent(eventId: string) {
    const event = await this.getEventById(eventId);
    await this.eventRepository.removeAndFlush(event);
    return event;
  }

  async removeChallenge(challengeId: string) {
    const challenge = await this.challengeRepository.findOneOrFail({
      id: challengeId,
    });
    const event = await challenge.linkedEvent.load();
    await this.challengeRepository.removeAndFlush(challenge);
    return event;
  }

  /** Get rewards of the user */
  async getRewards(ids: string[]): Promise<EventReward[]> {
    return await this.rewardRepository.find({ id: ids });
  }

  /** Deletes all rewards with IDs listed in removeIds.
   * Does nothing if the reward's ID is not in the user's rewards. */
  async deleteRewards(removeIds: string[]) {
    return await Promise.all(
      removeIds.map(async id => {
        const reward = await this.rewardRepository.findOneOrFail({
          id,
        });
        const ev = await reward.containingEvent.load();
        await this.rewardRepository.removeAndFlush(reward);
        return ev;
      }),
    );
  }

  /** Creates a EventReward given RewardDto reward */
  async createRewardFromUpdateDTO(reward: RewardDto): Promise<EventReward> {
    let rewardEntity = await this.rewardRepository.findOne({ id: reward.id });

    if (rewardEntity) {
      rewardEntity.rewardDescription = reward.description.substring(0, 2048);
      rewardEntity.rewardRedeemInfo = reward.redeemInfo.substring(0, 2048);
    } else {
      rewardEntity = this.rewardRepository.create({
        id: v4(),
        containingEvent: await this.eventRepository.findOneOrFail({
          id: reward.containingEventId,
        }),
        rewardDescription: reward.description.substring(0, 2048),
        rewardRedeemInfo: reward.redeemInfo.substring(0, 2048),
        isRedeemed: false,
      });
    }

    await this.rewardRepository.persistAndFlush(rewardEntity);
    return rewardEntity;
  }

  async createEventFromUpdateDTO(event: EventDto): Promise<EventBase> {
    let eventEntity = await this.eventRepository.findOne({ id: event.id });
    const assignData = {
      requiredMembers: event.requiredMembers,
      skippingEnabled: event.skippingEnabled,
      isDefault: event.isDefault,
      name: event.name.substring(0, 2048),
      description: event.description.substring(0, 2048),
      rewardType:
        event.rewardType === 'limited_time_event'
          ? EventRewardType.LIMITED_TIME_EVENT
          : EventRewardType.PERPETUAL,
      time: new Date(event.time),
      indexable: event.indexable,
    };

    if (eventEntity) {
      Object.assign(eventEntity, assignData);
      eventEntity.challenges.set(
        await this.challengeRepository.find({
          id: event.challengeIds,
        }),
      );
      eventEntity.rewards.set(
        await this.rewardRepository.find({ id: event.rewardIds }),
      );
    } else {
      eventEntity = this.eventRepository.create({
        ...assignData,
        id: v4(),
        challenges: [],
        rewards: [],
      });
    }

    (await eventEntity?.challenges.loadItems())?.forEach(challenge => {
      challenge.eventIndex = event.challengeIds.indexOf(challenge.id);
    });

    await this.eventRepository.persistAndFlush(eventEntity);
    return eventEntity;
  }

  async createChallengeFromUpdateDTO(
    challenge: ChallengeDto,
  ): Promise<Challenge> {
    const assignData = {
      name: challenge.name.substring(0, 2048),
      description: challenge.description.substring(0, 2048),
      imageUrl: challenge.imageUrl.substring(0, 2048),
      latitude: challenge.latitude,
      longitude: challenge.longitude,
      awardingRadius: challenge.awardingRadius,
      closeRadius: challenge.closeRadius,
    };

    let challengeEntity = await this.challengeRepository.findOne({
      id: challenge.id,
    });

    if (challengeEntity) {
      Object.assign(challengeEntity, assignData);
    } else {
      const thisEvent = await this.eventRepository.findOneOrFail({
        id: challenge.containingEventId,
      });

      const maxIndexChallenge = await this.challengeRepository.findOne(
        {
          linkedEvent: thisEvent,
        },
        { orderBy: { eventIndex: 'DESC' } },
      );

      const newEventIndex = (maxIndexChallenge?.eventIndex ?? -1) + 1;
      challengeEntity = this.challengeRepository.create({
        ...assignData,
        id: v4(),
        eventIndex: newEventIndex,
        linkedEvent: thisEvent,
        completions: [],
      });
    }

    this.challengeRepository.persistAndFlush(challengeEntity);
    return challengeEntity;
  }

  /** Updates the repository with all rewards listed in rewards.
   * Adds a new reward if it does not exist, otherwise overwrites the
   * old reward. */
  async updateRewards(rewards: RewardDto[]): Promise<EventReward[]> {
    return await Promise.all(
      rewards.map(rw => this.createRewardFromUpdateDTO(rw)),
    );
  }

  async updateEvents(events: EventDto[]): Promise<EventBase[]> {
    return await Promise.all(
      events.map(ev => this.createEventFromUpdateDTO(ev)),
    );
  }

  async updateChallenges(challenges: ChallengeDto[]): Promise<Challenge[]> {
    return await Promise.all(
      challenges.map(ch => this.createChallengeFromUpdateDTO(ch)),
    );
  }
}
