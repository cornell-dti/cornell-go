import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { CallingUser } from 'src/auth/calling-user.decorator';
import { AdminGuard } from 'src/auth/jwt-auth.guard';
import { ClientService } from 'src/client/client.service';
import { AdminCallbackService } from './admin-callback/admin-callback.service';
import { UpdateAdminDataAdminDto } from './admin-callback/update-admin-data.dto';
import { UpdateEventDataDto } from './admin-callback/update-event-data.dto';
import { UpdateRewardDataDto } from './admin-callback/update-reward-data.dto';
import { AdminService } from './admin.service';
import { RequestAdminsDto } from './request-admins.dto';
import { RequestChallengesDto } from './request-challenges.dto';
import { RequestEventsDto } from './request-events.dto';
import { RequestGroupsDto } from './request-groups.dto';
import { RequestRestrictionsDto } from './request-restrictions.dto';
import { RequestRewardsDto } from './request-rewards.dto';
import { UpdateAdminsDto } from './update-admins.dto';
import { UpdateChallengesDto } from './update-challenges.dto';
import { UpdateEventsDto } from './update-events.dto';
import { UpdateGroupsDto } from './update-groups.dto';
import { UpdateRestrictionsDto } from './update-restrictions.dto';
import { UpdateRewardsDto } from './update-rewards.dto';
@WebSocketGateway({ cors: true })
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
        events: await Promise.all(
          events.map(ev => this.adminService.dtoForEvent(ev)),
        ),
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
        challenges: await Promise.all(
          challenges.map(ch => this.adminService.dtoForChallenge(ch)),
        ),
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
      rewards: await Promise.all(
        rewardData.map(rw => this.adminService.dtoForReward(rw)),
      ),
      deletedIds: [],
    };
    this.adminCallbackService.emitUpdateRewardData(updateRewardData, user);
    return false;
  }

  @SubscribeMessage('requestGroups')
  async requestGroups(
    @CallingUser() user: User,
    @MessageBody() data: RequestGroupsDto,
  ) {
    const groups = await this.adminService.getAllGroupData();

    this.adminCallbackService.emitUpdateGroupData(
      {
        deletedIds: [],
        groups: await Promise.all(
          groups.map(gr => this.adminService.dtoForGroup(gr)),
        ),
      },
      user,
    );
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
          restrictionGroups.map(rg =>
            this.adminService.dtoForRestrictionGroup(rg),
          ),
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
      events: await Promise.all(
        newEvents.map(ev => this.adminService.dtoForEvent(ev)),
      ),
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
        ).map(ev => this.adminService.dtoForEvent(ev)),
      ),
    });

    const newChallenges = await this.adminService.updateChallenges(
      data.challenges,
    );

    this.adminCallbackService.emitUpdateChallengeData({
      challenges: await Promise.all(
        newChallenges.map(ch => this.adminService.dtoForChallenge(ch)),
      ),
      deletedIds: data.deletedIds,
    });

    this.adminCallbackService.emitUpdateEventData({
      deletedIds: [],
      events: await Promise.all(
        (
          await Promise.all(
            newChallenges.map(ch =>
              this.adminService.eventForId(ch.linkedEventId),
            ),
          )
        ).map(ev => this.adminService.dtoForEvent(ev)),
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
        ).map(ev => this.adminService.dtoForEvent(ev)),
      ),
    });

    const rewards = await this.adminService.updateRewards(data.rewards);

    const newEventDto: UpdateEventDataDto = {
      events: await Promise.all(
        (
          await Promise.all(
            rewards.map(rw => this.adminService.eventForId(rw.eventId)),
          )
        ).map(ev => this.adminService.dtoForEvent(ev)),
      ),
      deletedIds: [],
    };

    this.adminCallbackService.emitUpdateRewardData({
      rewards: await Promise.all(
        rewards.map(rw => this.adminService.dtoForReward(rw)),
      ),
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

  @SubscribeMessage('updateGroups')
  async updateGroups(
    @CallingUser() user: User,
    @MessageBody() data: UpdateGroupsDto,
  ) {
    await Promise.all(
      data.deletedIds.map(gr => this.adminService.removeGroup(gr)),
    );

    const newGroups = await this.adminService.updateGroups(data.groups);

    this.adminCallbackService.emitUpdateGroupData({
      groups: await Promise.all(
        newGroups.map(gr => this.adminService.dtoForGroup(gr)),
      ),
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
      restrictions: await Promise.all(
        updated.map(rg => this.adminService.dtoForRestrictionGroup(rg)),
      ),
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
}
