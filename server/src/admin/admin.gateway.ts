import { UseFilters, UseGuards } from '@nestjs/common';
import {
  BaseWsExceptionFilter,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { CallingUser } from 'src/auth/calling-user.decorator';
import { AdminGuard } from 'src/auth/jwt-auth.guard';
import { User } from 'src/model/user.entity';
import { EventBase } from 'src/model/event-base.entity';
import { AdminCallbackService } from './admin-callback/admin-callback.service';
import { UpdateAdminDataAdminDto } from './admin-callback/update-admin-data.dto';
import { AdminService } from './admin.service';
import { ClientService } from 'src/client/client.service';
import { RewardService } from 'src/reward/reward.service';
import { RequestAdminsDto } from './request-admins.dto';
import { RequestChallengesDto } from './request-challenges.dto';
import { RequestEventsDto } from './request-events.dto';
import { RequestRewardsDto } from './request-rewards.dto';
import { UpdateRewardDataDto } from './admin-callback/update-reward-data.dto';
import { UpdateAdminsDto } from './update-admins.dto';
import { ChallengeDto, UpdateChallengesDto } from './update-challenges.dto';
import { EventDto, UpdateEventsDto } from './update-events.dto';
import { RewardDto, UpdateRewardsDto } from './update-rewards.dto';
import { Challenge } from 'src/model/challenge.entity';
import { EventReward } from 'src/model/event-reward.entity';
import { v4 } from 'uuid';
import { UpdateEventDataDto } from './admin-callback/update-event-data.dto';
import {
  RequestRestrictionsDto,
  RestrictionDto,
} from './request-restrictions.dto';
import { RestrictionGroup } from 'src/model/restriction-group.entity';
import { UpdateRestrictionsDto } from './update-restrictions.dto';
import { AllExceptionsFilter } from './admin-error-filter';
@WebSocketGateway({ cors: true })
@UseFilters(AllExceptionsFilter)
@UseGuards(AdminGuard)
export class AdminGateway {
  constructor(
    private adminService: AdminService,
    private adminCallbackService: AdminCallbackService,
    private clientService: ClientService,
  ) {}

  @SubscribeMessage('requestEvents')
  async requestEvents(
    @CallingUser() user: User,
    @MessageBody() data: RequestEventsDto,
  ) {
    const events = await this.adminService.getAllEventData();

    this.adminCallbackService.emitUpdateEventData(
      {
        deletedIds: [],
        events: await Promise.all(events.map(this.dtoForEvent)),
      },
      user,
    );
  }

  @SubscribeMessage('requestChallenges')
  async requestChallenges(
    @CallingUser() user: User,
    @MessageBody() data: RequestChallengesDto,
  ) {
    const challenges = await this.adminService.getAllChallengeData();

    this.adminCallbackService.emitUpdateChallengeData(
      {
        deletedIds: [],
        challenges: await Promise.all(challenges.map(this.dtoForChallenge)),
      },
      user,
    );
  }

  @SubscribeMessage('requestRewards')
  async requestRewards(
    @CallingUser() user: User,
    @MessageBody() data: RequestRewardsDto,
  ) {
    const rewardData = await this.adminService.getRewards(data.rewardIds);

    const updateRewardData: UpdateRewardDataDto = {
      rewards: await Promise.all(rewardData.map(this.dtoForReward)),
      deletedIds: [],
    };
    this.adminCallbackService.emitUpdateRewardData(updateRewardData, user);
    return false;
  }

  @SubscribeMessage('requestAdmins')
  async requestAdmins(
    @CallingUser() user: User,
    @MessageBody() data: RequestAdminsDto,
  ) {
    const admins = await this.adminService.getAllRequestingAdmins();
    // Only send to the requester
    this.adminCallbackService.emitUpdateAdminData(
      {
        admins: admins.map(usr => ({
          id: usr.id,
          requesting: true,
          email: usr.email,
          superuser: usr.superuser,
        })),
      },
      user,
    );
  }

  @SubscribeMessage('requestRestrictions')
  async requestRestrictions(
    @CallingUser() user: User,
    @MessageBody() data: RequestRestrictionsDto,
  ) {
    const restrictionGroups =
      await this.adminService.getAllRestrictionGroupData();

    this.adminCallbackService.emitUpdateRestrictionData(
      {
        restrictions: await Promise.all(
          restrictionGroups.map(this.dtoForRestrictionGroup),
        ),
        deletedIds: [],
      },
      user,
    );
  }

  @SubscribeMessage('updateEvents')
  async updateEvents(
    @CallingUser() user: User,
    @MessageBody() data: UpdateEventsDto,
  ) {
    await Promise.all(
      data.deletedIds.map(ev => this.adminService.removeEvent(ev)),
    );

    const newEvents = await this.adminService.updateEvents(data.events);

    this.adminCallbackService.emitUpdateEventData({
      events: await Promise.all(newEvents.map(this.dtoForEvent)),
      deletedIds: data.deletedIds,
    });

    this.clientService.emitInvalidateData({
      userEventData: true,
      userRewardData: true,
      winnerRewardData: true,
      groupData: true,
      challengeData: true,
      leaderboardData: true,
    });
  }

  @SubscribeMessage('updateChallenges')
  async updateChallenges(
    @CallingUser() user: User,
    @MessageBody() data: UpdateChallengesDto,
  ) {
    this.adminCallbackService.emitUpdateEventData({
      deletedIds: [],
      events: await Promise.all(
        (
          await Promise.all(
            data.deletedIds.map(ch => this.adminService.removeChallenge(ch)),
          )
        ).map(this.dtoForEvent),
      ),
    });

    const newChallenges = await this.adminService.updateChallenges(
      data.challenges,
    );

    this.adminCallbackService.emitUpdateChallengeData({
      challenges: await Promise.all(newChallenges.map(this.dtoForChallenge)),
      deletedIds: data.deletedIds,
    });

    this.adminCallbackService.emitUpdateEventData({
      deletedIds: [],
      events: await Promise.all(
        (
          await Promise.all(newChallenges.map(ch => ch.linkedEvent.load()))
        ).map(this.dtoForEvent),
      ),
    });

    this.clientService.emitInvalidateData({
      userEventData: true,
      userRewardData: true,
      winnerRewardData: true,
      groupData: true,
      challengeData: true,
      leaderboardData: true,
    });
  }

  @SubscribeMessage('updateRewards')
  async updateRewards(
    @CallingUser() user: User,
    @MessageBody() data: UpdateRewardsDto,
  ) {
    this.adminCallbackService.emitUpdateEventData({
      deletedIds: [],
      events: await Promise.all(
        (
          await this.adminService.deleteRewards(data.deletedIds)
        ).map(this.dtoForEvent),
      ),
    });

    const rewards = await this.adminService.updateRewards(data.rewards);

    const newEventDto: UpdateEventDataDto = {
      events: await Promise.all(
        (
          await Promise.all(rewards.map(rw => rw.containingEvent.load()))
        ).map(this.dtoForEvent),
      ),
      deletedIds: [],
    };

    this.adminCallbackService.emitUpdateRewardData({
      rewards: await Promise.all(rewards.map(this.dtoForReward)),
      deletedIds: data.deletedIds,
    });

    this.adminCallbackService.emitUpdateEventData(newEventDto);

    this.clientService.emitInvalidateData({
      userEventData: true,
      userRewardData: true,
      winnerRewardData: true,
      groupData: true,
      challengeData: true,
      leaderboardData: true,
    });
  }

  @SubscribeMessage('updateAdmins')
  async updateAdmins(
    @CallingUser() user: User,
    @MessageBody() data: UpdateAdminsDto,
  ) {
    const adminUpdates: UpdateAdminDataAdminDto[] = [];
    for (const adminData of data.adminUpdates) {
      const admin = await this.adminService.setAdminStatus(
        adminData.id,
        adminData.granted,
      );
      if (admin) {
        adminUpdates.push({
          id: admin.id,
          email: admin.email,
          requesting: false,
          superuser: admin.superuser,
        });
      }
    }
    // Send to all that an admin was updated
    this.adminCallbackService.emitUpdateAdminData({ admins: adminUpdates });
  }

  @SubscribeMessage('updateRestrictions')
  async updateRestrictions(
    @CallingUser() user: User,
    @MessageBody() data: UpdateRestrictionsDto,
  ) {
    await this.adminService.deleteRestrictionGroups(data.deletedIds);
    const updated = await this.adminService.updateRestrictionGroups(
      data.restrictions,
    );

    await this.adminCallbackService.emitUpdateRestrictionData({
      restrictions: await Promise.all(updated.map(this.dtoForRestrictionGroup)),
      deletedIds: data.deletedIds,
    });

    this.clientService.emitInvalidateData({
      userEventData: true,
      userRewardData: true,
      winnerRewardData: true,
      groupData: true,
      challengeData: true,
      leaderboardData: true,
    });
  }

  async dtoForEvent(ev: EventBase): Promise<EventDto> {
    await ev.challenges.init();
    await ev.rewards.init();
    return {
      id: ev.id,
      skippingEnabled: ev.skippingEnabled,
      isDefault: ev.isDefault,
      name: ev.name,
      description: ev.description,
      rewardType: ev.rewardType as 'limited_time_event' | 'perpetual',
      time: ev.time.toUTCString(),
      requiredMembers: ev.requiredMembers,
      indexable: ev.indexable,
      challengeIds: (await ev.challenges.loadItems())
        .sort((a, b) => a.eventIndex - b.eventIndex)
        .map(c => c.id),
      rewardIds: ev.rewards.getIdentifiers(),
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
      containingEventId: ch.linkedEvent.id,
    };
  }

  async dtoForReward(rw: EventReward): Promise<RewardDto> {
    return {
      id: rw.id,
      description: rw.rewardDescription,
      redeemInfo: rw.rewardRedeemInfo,
      containingEventId: rw.containingEvent.id,
      claimingUserId: rw.claimingUser?.id ?? '',
    };
  }

  async dtoForRestrictionGroup(
    restrictionGroup: RestrictionGroup,
  ): Promise<RestrictionDto> {
    const genUsers = await restrictionGroup.generatedUsers.loadItems();
    await restrictionGroup.restrictedUsers.loadItems();
    await restrictionGroup.allowedEvents.loadItems();

    return {
      id: restrictionGroup.id,
      displayName: restrictionGroup.displayName,
      canEditUsername: restrictionGroup.canEditUsername,
      restrictedUsers: restrictionGroup.restrictedUsers.getIdentifiers(),
      allowedEvents: restrictionGroup.allowedEvents.getIdentifiers(),
      generatedUserCount: genUsers.length,
      generatedUserAuthIds: genUsers.map(u => u.authToken),
    };
  }
}
