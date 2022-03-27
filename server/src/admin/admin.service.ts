import { ChallengeDto } from './update-challenges.dto';
import { EventRewardType } from './../model/event-base.entity';
import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { Injectable } from '@nestjs/common';
import { Challenge } from 'src/model/challenge.entity';
import { EventBase } from 'src/model/event-base.entity';
import { EventReward } from 'src/model/event-reward.entity';
import { RewardDto } from './update-rewards.dto';
import { User } from 'src/model/user.entity';
import { EventDto } from './update-events.dto';
import { v4 } from 'uuid';

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

  /** Get rewards of the user */
  async getRewardsForUser(user: User): Promise<EventReward[]> {
    return user.rewards.getItems();
  }

  /** Deletes all rewards with IDs listed in removeIds.
   * Does nothing if the reward's ID is not in the user's rewards. */
  async deleteRewards(removeIds: string[]) {
    for (const i in removeIds) {
      const reward = await this.rewardRepository.findOneOrFail({
        id: removeIds[i],
      });
      await this.rewardRepository.removeAndFlush(reward);
    }
  }

  /** Creates a EventReward given RewardDto reward */
  async createFromUpdateDTO(reward: RewardDto): Promise<EventReward> {
    const event_reward = this.rewardRepository.create({
      id: reward.id,
      containingEvent: await this.eventRepository.findOneOrFail({
        id: reward.containingEventId,
      }),
      rewardDescription: reward.description,
      rewardRedeemInfo: reward.redeemInfo,
      isRedeemed: false,
    });
    await this.rewardRepository.persistAndFlush(event_reward);
    return event_reward;
  }

  async createEventFromUpdateDTO(event: EventDto): Promise<EventBase> {
    const new_event = this.eventRepository.create({
        id: event.id,
        requiredMembers: event.requiredMembers,
        skippingEnabled: event.skippingEnabled,
        isDefault:event.isDefault,
        name: event.name,
        description: event.description,
        rewardType: event.rewardType === "limited_time_event" ? EventRewardType.LIMITED_TIME_EVENT : EventRewardType.PERPETUAL,
        time: new Date(event.time),
        indexable: event.indexable,
        challenges: await this.challengeRepository.find({ id: event.challengeIds})        ,
        rewards: await this.eventRepository.find({ id: event.rewardIds})
        ,
    });
    await this.eventRepository.persistAndFlush(new_event);
    return new_event;
  }
  async createChallengeFromUpdateDTO(challenge: ChallengeDto): Promise<Challenge> {
    const new_challenge = this.challengeRepository.create({
      id: challenge.id,
      eventIndex: (await this.challengeRepository.find({id: challenge.id})).eventIndex,
      name: challenge.name,
      description: challenge.description,
      imageUrl: challenge.imageUrl,
      latitude: challenge.latitude,
      longitude: challenge.longitude,
      linkedEvent: challenge.linkedEvent,
      awardingRadius: challenge.awardingRadius,
      closeRadius: challenge.closeRadius,
    });
    await this.challengeRepository.persistAndFlush(new_challenge);
    return new_challenge;
  }
  


  /** Updates the repository with all rewards listed in rewards.
   * Adds a new reward if it does not exist, otherwise overwrites the
   * old reward. */
  async updateRewards(
    rewards: RewardDto[],
  ): Promise<[EventBase[], EventBase[]]> {
    var newEvents = Array();
    var oldEvents = Array();

    rewards.forEach(async reward => {
      if (reward.id === '') {
        reward.id = v4();
      }
      const eventReward = await this.createFromUpdateDTO(reward);
      const oldReward = await this.rewardRepository.findOne({
        id: eventReward.id,
      });
      if (oldReward === null) {
        newEvents.push(eventReward.containingEvent.getEntity());
      } else if (
        oldReward.containingEvent.id != eventReward.containingEvent.id
      ) {
        newEvents.push(eventReward.containingEvent.getEntity());
        oldEvents.push(oldReward.containingEvent.getEntity());
      }
      this.rewardRepository.persistAndFlush(eventReward);
    });
    return [oldEvents, newEvents];
  }
  
  
  async updateEvents(events: EventDto[]): Promise<EventBase[]> {
    var newEvents = Array();

    events.forEach(async event => {
      if (event.id === '') {
        event.id = v4();
      }
      const newEvent = await this.createEventFromUpdateDTO(event);
      const oldEvent = await this.eventRepository.findOne({id: event.id,});
      if (oldEvent === null) {
        newEvents.push(newEvent);
      } else if (oldEvent.id != newEvent.id) {
        newEvents.push(newEvent);
      }
      this.eventRepository.persistAndFlush(newEvent);
    });
    return newEvents;
  }
  async updateChallenges(challenges: ChallengeDto[]): Promise<Challenge[]> {
    var newChallenges = Array();

    challenges.forEach(async challenge => {
      if (challenge.id === '') {
        challenge.id = v4();
      }
      const newChallenge = await this.createChallengeFromUpdateDTO(challenge);
      const oldChallenge = await this.challengeRepository.findOne({id: challenge.id,});
      if (oldChallenge === null) {
        newChallenges.push(newChallenge);
      } else if (oldChallenge.id != newChallenge.id) {
        newChallenges.push(newChallenge);
      }
      this.challengeRepository.persistAndFlush(newChallenge);
    });
    return newChallenges;
  }
}
