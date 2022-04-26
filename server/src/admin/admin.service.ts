import { ChallengeDto } from './update-challenges.dto';
import { EventRewardType } from './../model/event-base.entity';
import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { ConsoleLogger, Injectable } from '@nestjs/common';
import { Challenge } from 'src/model/challenge.entity';
import { EventBase } from 'src/model/event-base.entity';
import { EventReward } from 'src/model/event-reward.entity';
import { RewardDto } from './update-rewards.dto';
import { AuthType, User } from 'src/model/user.entity';
import { EventDto } from './update-events.dto';
import { v4 } from 'uuid';
import { RestrictionGroup } from 'src/model/restriction-group.entity';
import { EventTracker } from 'src/model/event-tracker.entity';
import { RestrictionDto } from './request-restrictions.dto';
import { UserService } from 'src/user/user.service';
import { Reference } from '@mikro-orm/core';
import { Group } from 'src/model/group.entity';

const friendlyWords = require('friendly-words');

@Injectable()
export class AdminService {
  constructor(
    private userService: UserService,
    @InjectRepository(User) private userRepository: EntityRepository<User>,
    @InjectRepository(Group) private groupRepository: EntityRepository<Group>,
    @InjectRepository(EventReward)
    private rewardRepository: EntityRepository<EventReward>,
    @InjectRepository(EventBase)
    private eventRepository: EntityRepository<EventBase>,
    @InjectRepository(Challenge)
    private challengeRepository: EntityRepository<Challenge>,
    @InjectRepository(RestrictionGroup)
    private restrictionGroupRepository: EntityRepository<RestrictionGroup>,
    @InjectRepository(EventTracker)
    private eventTrackerRepository: EntityRepository<EventTracker>,
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
    return await this.eventRepository.findAll();
  }

  async getAllChallengeData() {
    return await this.challengeRepository.findAll();
  }

  async getAllRestrictionGroupData() {
    return await this.restrictionGroupRepository.findAll();
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
    const firstChallengeOfEvent = (await event.challenges.loadItems())[0];

    const usedTrackers = await this.eventTrackerRepository.find({
      currentChallenge: challenge,
    });

    if (usedTrackers.length > 0 && !firstChallengeOfEvent) return event;

    for (const tracker of usedTrackers) {
      tracker.currentChallenge.set(firstChallengeOfEvent);
    }

    await this.eventTrackerRepository.persistAndFlush(usedTrackers);
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

  async deleteRestrictionGroups(ids: string[]) {
    const restrictionGroups = await this.restrictionGroupRepository.find({
      id: ids,
    });

    for (const rGroup of restrictionGroups) {
      const genUsers = await rGroup.generatedUsers.loadItems();
      await Promise.all(genUsers.map(u => this.userService.deleteUser(u)));
    }

    await this.restrictionGroupRepository.removeAndFlush(restrictionGroups);
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
      minimumScore: event.minimumScore,
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

  /** Creates a new restricted user */
  async newRestrictedUser(
    name: string,
    word: string,
    group: RestrictionGroup,
  ): Promise<User> {
    const user = await this.userService.register(
      name + '@cornell.edu',
      word,
      10.019,
      10.019,
      AuthType.DEVICE,
      name,
    );

    user.restrictedBy = Reference.create(group);
    user.generatedBy = Reference.create(group);

    await this.userService.saveUser(user);
    return user;
  }

  /** Adjusts member count in a group up or down based on expectedCount */
  async generateMembers(group: RestrictionGroup, expectedCount: number) {
    const genCount = await group.generatedUsers.loadCount();

    if (genCount < expectedCount) {
      const genUsers = await group.generatedUsers.loadItems();
      group.generatedUsers.remove(...genUsers.slice(expectedCount));
    } else {
      const seed = group.id[0].charCodeAt(0);
      for (let i = genCount; i < expectedCount; ++i) {
        const word =
          friendlyWords.objects[(10 * i + seed) % friendlyWords.objects.length];
        const newName = group.name + '_' + word;
        const user = await this.newRestrictedUser(newName, word, group);

        group.generatedUsers.add(user);
        group.restrictedUsers.add(user);
      }
    }
  }

  /** Ensures all restricted users are on an allowed event */
  async ensureEventRestriction(group: RestrictionGroup) {
    const allowedEventCount = await group.allowedEvents.loadCount();

    if (allowedEventCount === 0) {
      return; // No event restrictions
    }

    const allowedEvents = await group.allowedEvents.loadItems();
    const allowedEvent = allowedEvents[0];

    const violatingGroups = await this.groupRepository.find({
      host: {
        restrictedBy: group,
      },
      currentEvent: { $nin: allowedEvents },
    });

    for (const group of violatingGroups) {
      group.currentEvent.set(allowedEvent);
      await this.groupRepository.persistAndFlush(group);
    }
  }

  /** Update/insert a restriction group */
  async updateRestrictionGroupWithDto(restriction: RestrictionDto) {
    const curRestriction = await this.restrictionGroupRepository.findOne({
      id: restriction.id,
    });

    const assignData = {
      displayName: restriction.displayName,
      name: restriction.displayName.toLowerCase().replaceAll(/[^a-z0-9]/g, '_'),
      canEditUsername: restriction.canEditUsername,
    };

    const restrictedUsers = await this.userRepository.find({
      id: restriction.restrictedUsers,
    });

    const allowedEvents = await this.eventRepository.find({
      id: restriction.allowedEvents,
    });

    if (curRestriction) {
      const genCount = await curRestriction.generatedUsers.loadCount();
      if (restriction.generatedUserCount < genCount) {
        return curRestriction;
      }
    }

    const restrictionGroupEntity =
      curRestriction ??
      this.restrictionGroupRepository.create({
        id: v4(),
        ...assignData,
      });

    if (curRestriction) {
      Object.assign(curRestriction, assignData);
    }

    restrictionGroupEntity.restrictedUsers.set(restrictedUsers);
    restrictionGroupEntity.allowedEvents.set(allowedEvents);

    await this.restrictionGroupRepository.persistAndFlush(
      restrictionGroupEntity,
    );

    await this.generateMembers(
      restrictionGroupEntity,
      restriction.generatedUserCount,
    );

    await this.ensureEventRestriction(restrictionGroupEntity);

    return restrictionGroupEntity;
  }

  async updateRestrictionGroups(
    restrictions: RestrictionDto[],
  ): Promise<RestrictionGroup[]> {
    return await Promise.all(
      restrictions.map(r => this.updateRestrictionGroupWithDto(r)),
    );
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
