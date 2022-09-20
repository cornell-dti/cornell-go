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
import { ClientService } from 'src/client/client.service';

const friendlyWords = require('friendly-words');

@Injectable()
export class AdminService {
  constructor(
    private userService: UserService,
    private clientService: ClientService,
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
  ) { }

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
    id: string,
    word: string,
    group: RestrictionGroup,
  ): Promise<User> {
    const user = await this.userService.register(
      id + '@cornell.edu',
      word,
      10.019,
      10.019,
      AuthType.DEVICE,
      id,
    );

    user.restrictedBy = Reference.create(group);
    user.generatedBy = Reference.create(group);

    await this.userService.saveUser(user);
    return user;
  }

  /** Adjusts member count in a group up based on expectedCount */
  async generateMembers(group: RestrictionGroup, expectedCount: number) {
    const genCount = await group.generatedUsers.loadCount();

    if (genCount < expectedCount) {
      const seed = group.id[0].charCodeAt(0);
      for (let i = genCount; i < expectedCount; ++i) {
        const index = (10 * i + seed) % friendlyWords.objects.length;
        const word = friendlyWords.objects[index];
        const id = group.name + '_' + word + index;
        const user = await this.newRestrictedUser(id, word, group);

        group.generatedUsers.add(user);
        group.restrictedUsers.add(user);
      }
    }

    await this.restrictionGroupRepository.persistAndFlush(group);
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

    for (const userGroup of violatingGroups) {
      userGroup.currentEvent.set(allowedEvent);
      await this.groupRepository.persistAndFlush(userGroup);
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

    const genCount = await restrictionGroupEntity.generatedUsers.loadCount();

    if (restriction.generatedUserCount > genCount) {
      await this.generateMembers(
        restrictionGroupEntity,
        restriction.generatedUserCount,
      );
    }

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

  async checkEventTrackers() {
    const users = await this.userRepository.findAll();
    let invalidateRewardData = false;
    let invalidateEventData = false;
    let invalidateLeaderboardData = false;

    for (const usr of users) {
      const all_user_trackers = await usr.participatingEvents.loadItems();
      const seen_trackers = []; // Consists of already seen trackers

      for (const t of all_user_trackers) {
        let dupFound = false;
        for (const existing_t of seen_trackers) {
          // checks if current tracker's event has already been seen
          if (t.event.id === existing_t.event.id) {
            dupFound = true;
            let rewards_to_remove;
            // keep event tracker that has higher score
            if (t.eventScore > existing_t.eventScore) {
              usr.participatingEvents.remove(existing_t);
              rewards_to_remove = (await existing_t.event.load()).rewards;
              // replace existing_t in seen_trackers with t, since t has
              // the higher score and should be compared to other duplicate
              // trackers from now on
              seen_trackers.splice(seen_trackers.indexOf(existing_t), 1, t);
            } else {
              usr.participatingEvents.remove(t);
              rewards_to_remove = (await t.event.load()).rewards;
            }
            // removes any rewards related to duplicate event tracker
            for (const rwd of rewards_to_remove) {
              if (usr.rewards.contains(rwd)) {
                usr.rewards.remove(rwd);
              }
            }
            invalidateEventData = true;
          }
        }
        if (!dupFound) seen_trackers.push(t);
      }
      // updates score if some events have been deleted
      let new_score = 0;
      for (const t of usr.participatingEvents) {
        new_score += t.eventScore;
      }
      usr.score = new_score;
      // save data in the userRepository
      await this.userRepository.persistAndFlush(usr);
      // changing user's score may change leaderboard positions
      invalidateLeaderboardData = true;
    }
    this.clientService.emitInvalidateData({
      userEventData: invalidateEventData,
      userRewardData: invalidateRewardData,
      winnerRewardData: false,
      groupData: false,
      challengeData: false,
      leaderboardData: invalidateLeaderboardData,
    });
  }
}
