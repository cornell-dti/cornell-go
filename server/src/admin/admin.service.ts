import { ChallengeDto } from './update-challenges.dto';
import { Injectable } from '@nestjs/common';
import { RewardDto } from './update-rewards.dto';
import { EventDto } from './update-events.dto';
import { v4 } from 'uuid';
import { RestrictionDto } from './request-restrictions.dto';
import { UserService } from 'src/user/user.service';
import { GroupService } from 'src/group/group.service';

import {
  AuthType,
  Challenge,
  EventBase,
  EventReward,
  EventRewardType,
  Group,
  PrismaClient,
  RestrictionGroup,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { GroupDto } from './update-groups.dto';

const friendlyWords = require('friendly-words');

@Injectable()
export class AdminService {
  constructor(
    private userService: UserService,
    private groupService: GroupService,
    private prisma: PrismaService,
  ) {}

  async requestAdminAccess(adminId: string) {
    console.log(`User ${adminId} requested admin access!`);

    await this.prisma.user.update({
      where: { id: adminId },
      data: { adminRequested: true },
    });
  }

  async setAdminStatus(adminId: string, granted: boolean) {
    console.log(
      `User was ${adminId} ${granted ? 'granted' : 'denied'} admin access!`,
    );

    return await this.prisma.user.update({
      where: { id: adminId },
      data: {
        adminGranted: granted,
        adminRequested: false,
      },
    });
  }

  async getAllRequestingAdmins() {
    return await this.prisma.user.findMany({ where: { adminRequested: true } });
  }

  async getAllEventData() {
    return await this.prisma.eventBase.findMany();
  }

  async getAllChallengeData() {
    return await this.prisma.challenge.findMany();
  }

  async getAllGroupData() {
    return await this.prisma.group.findMany();
  }

  async getAllRestrictionGroupData() {
    return await this.prisma.restrictionGroup.findMany();
  }

  async getEventById(eventId: string) {
    return await this.prisma.eventBase.findFirstOrThrow({
      where: { id: eventId },
    });
  }

  async getChallengeById(challengeId: string) {
    return await this.prisma.challenge.findFirstOrThrow({
      where: { id: challengeId },
    });
  }

  async getGroupById(groupId: string) {
    return await this.prisma.group.findFirstOrThrow({
      where: { id: groupId },
    });
  }

  async removeEvent(eventId: string) {
    return await this.prisma.eventBase.delete({ where: { id: eventId } });
  }

  async removeChallenge(challengeId: string) {
    const challenge = this.prisma.challenge.findFirstOrThrow({
      where: { id: challengeId },
    });

    const usedTrackers = await this.prisma.eventTracker.findMany({
      where: {
        curChallengeId: challengeId,
      },
    });

    const firstChallengeOfEvent = (
      await challenge.linkedEvent().challenges()
    )[0];

    if (usedTrackers.length > 0 && !firstChallengeOfEvent)
      return await challenge.linkedEvent();

    for (const tracker of usedTrackers) {
      this.prisma.eventTracker.update({
        where: { id: tracker.id },
        data: { curChallengeId: firstChallengeOfEvent.id },
      });
    }

    let tempChallenge = await challenge.linkedEvent();
    await this.prisma.challenge.delete({ where: { id: challengeId } });

    return tempChallenge;
  }

  /** Get rewards of the user */
  async getRewards(ids: string[]) {
    return await this.prisma.eventReward.findMany({
      where: { id: { in: ids } },
    });
  }

  /** Deletes all rewards with IDs listed in removeIds.
   * Does nothing if the reward's ID is not in the user's rewards. */
  async deleteRewards(removeIds: string[]) {
    return await Promise.all(
      removeIds.map(async id => {
        const reward = this.prisma.eventReward.findFirstOrThrow({
          where: {
            id,
          },
        });
        let tempEvent = await reward.event();
        await this.prisma.eventReward.delete({
          where: { id },
        });
        return tempEvent;
      }),
    );
  }

  async removeGroup(removeId: string) {
    const deletedGroup = await this.prisma.group.findFirstOrThrow({
      where: { id: removeId },
      include: { members: true },
    });

    await Promise.all(
      deletedGroup.members.map(us => this.groupService.leaveGroup(us)),
    );

    await this.prisma.group.delete({ where: { id: removeId } });
  }

  async deleteRestrictionGroups(ids: string[]) {
    const genedUsers = await this.prisma.user.findMany({
      where: { generatedById: { in: ids } },
    });

    await Promise.all(genedUsers.map(u => this.userService.deleteUser(u)));

    await this.prisma.restrictionGroup.deleteMany({
      where: { id: { in: ids } },
    });
  }

  /** Creates a EventReward given RewardDto reward */
  async createRewardFromUpdateDTO(reward: RewardDto) {
    let rewardEntity = await this.prisma.eventReward.findFirst({
      where: { id: reward.id },
    });

    if (rewardEntity) {
      rewardEntity = await this.prisma.eventReward.update({
        where: { id: reward.id },
        data: {
          description: reward.description.substring(0, 2048),
          redeemInfo: reward.redeemInfo.substring(0, 2048),
        },
      });
    } else {
      rewardEntity = await this.prisma.eventReward.create({
        data: {
          eventId: reward.containingEventId,
          eventIndex: -10,
          description: reward.description.substring(0, 2048),
          redeemInfo: reward.redeemInfo.substring(0, 2048),
          isRedeemed: false,
        },
      });
      if (rewardEntity.eventIndex === -10) {
        const maxIndexReward = await this.prisma.eventReward.findFirst({
          where: { eventId: reward.containingEventId },
          orderBy: { eventIndex: 'desc' },
        });

        await this.prisma.eventReward.update({
          where: { id: rewardEntity.id },
          data: {
            eventIndex: Math.max((maxIndexReward?.eventIndex ?? -1) + 1, 0),
          },
        });
      }
    }

    return rewardEntity;
  }

  async createEventFromUpdateDTO(event: EventDto) {
    const assignData = {
      requiredMembers: event.requiredMembers,
      skippingEnabled: event.skippingEnabled,
      isDefault: event.isDefault,
      name: event.name.substring(0, 2048),
      description: event.description.substring(0, 2048),
      rewardType:
        event.rewardType === 'limited_time_event'
          ? EventRewardType.LIMITED_TIME
          : EventRewardType.PERPETUAL,
      endTime: new Date(event.time),
      indexable: event.indexable,
      minimumScore: event.minimumScore,
    };

    const eventEntity = await this.prisma.eventBase.upsert({
      where: { id: event.id },
      create: assignData,
      update: {
        ...assignData,
        challenges: {
          set: event.challengeIds.map(id => ({ id })),
        },
        rewards: {
          set: event.rewardIds.map(id => ({ id })),
        },
      },
    });

    let eventIndex = 0;
    for (const id of event.challengeIds) {
      await this.prisma.challenge.update({
        where: { id },
        data: {
          eventIndex,
        },
      });

      ++eventIndex;
    }

    let eventIndex1 = 0;
    for (const id of event.rewardIds) {
      await this.prisma.eventReward.update({
        where: { id },
        data: {
          eventIndex: eventIndex1,
        },
      });

      ++eventIndex1;
    }

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

    const challengeEntity = await this.prisma.challenge.upsert({
      where: { id: challenge.id },
      update: assignData,
      create: {
        ...assignData,
        eventIndex: -10,
        linkedEventId: challenge.containingEventId,
      },
    });

    if (challengeEntity.eventIndex === -10) {
      const maxIndexChallenge = await this.prisma.challenge.findFirst({
        where: { linkedEventId: challenge.containingEventId },
        orderBy: { eventIndex: 'desc' },
      });

      await this.prisma.challenge.update({
        where: { id: challengeEntity.id },
        data: {
          eventIndex: Math.max((maxIndexChallenge?.eventIndex ?? -1) + 1, 0),
        },
      });
    }

    return challengeEntity;
  }

  async updateGroup(group: GroupDto): Promise<Group> {
    const groupEntity = await this.prisma.group.update({
      where: { id: group.id },
      data: {
        id: group.id,
        friendlyId: group.friendlyId,
        hostId: group.hostId,
        curEventId: group.curEventId,
      },
    });

    return groupEntity;
  }

  /** Creates a new restricted user */
  async newRestrictedUser(id: string, word: string, group: RestrictionGroup) {
    const user = await this.userService.register(
      id + '@cornell.edu',
      word,
      10.019,
      10.019,
      AuthType.DEVICE,
      id,
    );

    return await this.prisma.user.update({
      where: { id: user.id },
      data: { restrictedById: group.id, generatedById: group.id },
    });
  }

  /** Adjusts member count in a group up based on expectedCount */
  async generateMembers(group: RestrictionGroup, expectedCount: number) {
    const genCount = await this.prisma.user.count({
      where: { generatedById: group.id },
    });

    if (genCount < expectedCount) {
      const seed = group.id[0].charCodeAt(0);
      for (let i = genCount; i < expectedCount; ++i) {
        const index = (10 * i + seed) % friendlyWords.objects.length;
        const word = friendlyWords.objects[index];
        const id = group.name + '_' + word + index;
        const user = await this.newRestrictedUser(id, word, group);

        await this.prisma.restrictionGroup.update({
          where: { id: group.id },
          data: {
            generatedUsers: { connect: { id: user.id } },
            restrictedUsers: { connect: { id: user.id } },
          },
        });
      }
    }
  }

  /** Ensures all restricted users are on an allowed event */
  async ensureEventRestriction(group: RestrictionGroup) {
    const allowedEventCount = await this.prisma.eventBase.count({
      where: {
        allowedIn: { some: { id: group.id } },
      },
    });

    if (allowedEventCount === 0) {
      return; // No event restrictions
    }

    const allowedEvents = (
      await this.prisma.eventBase.findMany({
        where: { allowedIn: { some: { id: group.id } } },
      })
    ).map(({ id }) => id);

    const violatingGroups = await this.prisma.group.findMany({
      where: {
        host: { restrictedBy: group },
        curEventId: { notIn: allowedEvents },
      },
    });

    for (const userGroup of violatingGroups) {
      await this.prisma.group.update({
        where: { id: userGroup.id },
        data: { curEventId: allowedEvents[0] },
      });
    }
  }

  /** Update/insert a restriction group */
  async updateRestrictionGroupWithDto(restriction: RestrictionDto) {
    const restrictionEntity = await this.prisma.restrictionGroup.upsert({
      where: { id: restriction.id },
      create: {
        displayName: restriction.displayName,
        name: restriction.displayName
          .toLowerCase()
          .replaceAll(/[^a-z0-9]/g, '_'),
        canEditUsername: restriction.canEditUsername,
        restrictedUsers: {
          connect: restriction.restrictedUsers.map(id => ({ id })),
        },
        allowedEvents: {
          connect: restriction.allowedEvents.map(id => ({ id })),
        },
      },
      update: {
        restrictedUsers: {
          set: restriction.restrictedUsers.map(id => ({ id })),
        },
        allowedEvents: {
          set: restriction.allowedEvents.map(id => ({ id })),
        },
      },
    });

    const genCount = await this.prisma.user.count({
      where: { generatedBy: restrictionEntity },
    });

    if (restriction.generatedUserCount > genCount) {
      await this.generateMembers(
        restrictionEntity,
        restriction.generatedUserCount,
      );
    }

    await this.ensureEventRestriction(restrictionEntity);

    return restrictionEntity;
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
  async updateRewards(rewards: RewardDto[]) {
    return await Promise.all(
      rewards.map(rw => this.createRewardFromUpdateDTO(rw)),
    );
  }

  async updateEvents(events: EventDto[]) {
    return await Promise.all(
      events.map(ev => this.createEventFromUpdateDTO(ev)),
    );
  }

  async updateChallenges(challenges: ChallengeDto[]) {
    return await Promise.all(
      challenges.map(ch => this.createChallengeFromUpdateDTO(ch)),
    );
  }
  async updateGroups(groups: GroupDto[]) {
    return await Promise.all(groups.map(gr => this.updateGroup(gr)));
  }
  async eventForId(eventId: string) {
    return await this.prisma.eventBase.findUniqueOrThrow({
      where: { id: eventId },
    });
  }

  async dtoForEvent(ev: EventBase): Promise<EventDto> {
    const chals = await this.prisma.challenge.findMany({
      where: { linkedEventId: ev.id },
    });

    const rwIds = await this.prisma.eventReward.findMany({
      where: { eventId: ev.id },
      select: { id: true },
    });

    return {
      id: ev.id,
      skippingEnabled: ev.skippingEnabled,
      isDefault: ev.isDefault,
      name: ev.name,
      description: ev.description,
      rewardType:
        ev.rewardType == EventRewardType.LIMITED_TIME
          ? 'limited_time_event'
          : 'perpetual',
      time: ev.endTime.toUTCString(),
      requiredMembers: ev.requiredMembers,
      indexable: ev.indexable,
      challengeIds: chals
        .sort((a, b) => a.eventIndex - b.eventIndex)
        .map(c => c.id),
      rewardIds: rwIds.map(({ id }) => id),
      minimumScore: ev.minimumScore,
    };
  }

  async dtoForChallenge(ch: Challenge): Promise<ChallengeDto> {
    return {
      id: ch.id,
      name: ch.name,
      description: ch.description,
      imageUrl: ch.imageUrl,
      latitude: ch.latitude,
      longitude: ch.longitude,
      awardingRadius: ch.awardingRadius,
      closeRadius: ch.closeRadius,
      containingEventId: ch.linkedEventId,
    };
  }

  async dtoForReward(rw: EventReward): Promise<RewardDto> {
    return {
      id: rw.id,
      description: rw.description,
      redeemInfo: rw.redeemInfo,
      containingEventId: rw.eventId,
      claimingUserId: rw.userId ?? '',
    };
  }

  async dtoForGroup(gr: Group): Promise<GroupDto> {
    return {
      id: gr.id,
      friendlyId: gr.friendlyId,
      hostId: gr.hostId!,
      curEventId: gr.curEventId,
    };
  }

  async dtoForRestrictionGroup(
    restrictionGroup: RestrictionGroup,
  ): Promise<RestrictionDto> {
    const fullRestric = this.prisma.restrictionGroup.findUniqueOrThrow({
      where: { id: restrictionGroup.id },
    });

    const genUsers = await fullRestric.generatedUsers();

    return {
      id: restrictionGroup.id,
      displayName: restrictionGroup.displayName,
      canEditUsername: restrictionGroup.canEditUsername,
      restrictedUsers: (
        await fullRestric.restrictedUsers({ select: { id: true } })
      ).map(e => e.id),
      allowedEvents: (
        await fullRestric.allowedEvents({ select: { id: true } })
      ).map(e => e.id),
      generatedUserCount: genUsers.length,
      generatedUserAuthIds: genUsers.map(u => u.authToken),
    };
  }
}
