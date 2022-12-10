import { ChallengeDto } from './update-challenges.dto';
import { Injectable } from '@nestjs/common';
import { RewardDto } from './update-rewards.dto';
import { EventDto } from './update-events.dto';
import { v4 } from 'uuid';
import { OrganizationDto } from './request-organizations.dto';
import { UserService } from 'src/user/user.service';
import { GroupService } from 'src/group/group.service';
import { OrganizationService } from 'src/organization/organization.service';
import { EventService } from 'src/event/event.service';

import {
  AuthType,
  Challenge,
  EventBase,
  EventReward,
  EventRewardType,
  PrismaClient,
  Organization,
  OrganizationSpecialUsage,
  Group,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

const friendlyWords = require('friendly-words');

@Injectable()
export class AdminService {
  constructor(
    private userService: UserService,
    private groupService: GroupService,
    private orgService: OrganizationService,
    private eventService: EventService,
    private prisma: PrismaService,
  ) { }

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

  async getAllOrganizationData() {
    return await this.prisma.organization.findMany();
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

    await this.prisma.challenge.delete({ where: { id: challengeId } });

    return await challenge.linkedEvent();
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
        await this.prisma.eventReward.delete({
          where: { id },
        });
        return await reward.event();
      }),
    );
  }

  async deleteOrganizations(ids: string[]) {
    // for (const id of ids) {
    //   const genedUsers = await this.prisma.user.findMany({
    //     where: { generatedById: { has: id } },
    //   });
    // }

    // await Promise.all(genedUsers.map(u => this.userService.deleteUser(u)));

    await this.prisma.organization.deleteMany({
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
          description: reward.description.substring(0, 2048),
          redeemInfo: reward.redeemInfo.substring(0, 2048),
          isRedeemed: false,
        },
      });
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
    for (const id of event.rewardIds) {
      await this.prisma.challenge.update({
        where: { id },
        data: {
          eventIndex,
        },
      });

      ++eventIndex;
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

  /** Adjusts member count in a group up based on expectedCount */
  // async generateMembers(group: Organization, expectedCount: number) {
  //   const genCount = await this.prisma.user.count({
  //     where: { generatedById: group.id },
  //   });

  //   if (genCount < expectedCount) {
  //     const seed = group.id[0].charCodeAt(0);
  //     for (let i = genCount; i < expectedCount; ++i) {
  //       const index = (10 * i + seed) % friendlyWords.objects.length;
  //       const word = friendlyWords.objects[index];
  //       const id = group.name + '_' + word + index;
  //       const user = await this.newUser(id, word, group);

  //       await this.prisma.organization.update({
  //         where: { id: group.id },
  //         data: {
  //           members: { connect: { id: user.id } },
  //         },
  //       });
  //     }
  //   }
  // }

  /** 
   * Take in a group and check if the group's current event is allowed for 
   * everyone. if not, assign default allowed event to group
   */
  async ensureValidGroupEvent(group: Group) {
    const allowedEvents = await this.groupService.getAllowedEventIds(group)

    if (!allowedEvents?.includes(group.curEventId)) {
      const hostOrgs = (await this.prisma.organization.findMany({
        where: { members: { some: { id: group.hostId! } } },
        select: { id: true }
      })).map((org) => org.id)

      // every member of the group must have this default org (?)
      const defaultOrg = await this.prisma.organization.findFirstOrThrow({
        where: { isDefault: true, id: { in: hostOrgs } }
      })

      let newEvent = await this.orgService.getDefaultEvent(defaultOrg);

      const groupMembers = await this.groupService.getMembers(group);

      await Promise.all(
        groupMembers.map(async (member) => {
          await this.eventService.createEventTracker(member, newEvent);
        }),
      );

      await this.prisma.group.update({
        where: { id: group.id },
        data: { curEventId: newEvent.id }
      })

    }

  }

  /** Update/insert a organization group */
  async updateOrganizationWithDto(organization: OrganizationDto) {
    const organizationEntity = await this.prisma.organization.upsert({
      where: { id: organization.id },
      create: {
        displayName: organization.displayName,
        name: organization.displayName
          .toLowerCase()
          .replaceAll(/[^a-z0-9]/g, '_'),
        isDefault: false,
        canEditUsername: organization.canEditUsername,
        members: {
          connect: organization.members.map(id => ({ id })),
        },
        allowedEvents: {
          connect: organization.allowedEvents.map(id => ({ id })),
        },
        defaultEventId: organization.defaultEvent,
        specialUsage: 'NONE',
      },
      update: {
        members: {
          set: organization.members.map(id => ({ id })),
        },
        allowedEvents: {
          set: organization.allowedEvents.map(id => ({ id })),
        },
      },
    });

    // const genCount = await this.prisma.user.count({
    //   where: { generatedBy: organizationEntity },
    // });

    // if (organization.generatedUserCount > genCount) {
    //   await this.generateMembers(
    //     organizationEntity,
    //     organization.generatedUserCount,
    //   );
    // }

    return organizationEntity;
  }

  async updateOrganizations(
    organizations: OrganizationDto[],
  ): Promise<Organization[]> {
    return await Promise.all(
      organizations.map(r => this.updateOrganizationWithDto(r)),
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

  async dtoForOrganization(
    organization: Organization,
  ): Promise<OrganizationDto> {
    const org = this.prisma.organization.findUniqueOrThrow({
      where: { id: organization.id },
    });

    // const genUsers = await fullRestric.generatedUsers();

    return {
      id: organization.id,
      displayName: organization.displayName,
      isDefault: false,
      canEditUsername: organization.canEditUsername,
      members: (await org.members({ select: { id: true } })).map(e => e.id),
      allowedEvents: (await org.allowedEvents({ select: { id: true } })).map(
        e => e.id,
      ),
      defaultEvent: organization.defaultEventId,
      // generatedUserCount: genUsers.length,
      // generatedUserAuthIds: genUsers.map(u => u.authToken),
    };
  }
}
