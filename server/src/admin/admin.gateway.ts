import { UseGuards } from '@nestjs/common';
import {
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
import { RequestAdminsDto } from './request-admins.dto';
import { RequestChallengesDto } from './request-challenges.dto';
import { RequestEventsDto } from './request-events.dto';
import { RequestRewardsDto } from './request-rewards.dto';
import { UpdateAdminsDto } from './update-admins.dto';
import { UpdateChallengesDto } from './update-challenges.dto';
import { UpdateEventsDto } from './update-events.dto';
import { UpdateRewardsDto } from './update-rewards.dto';
import { Challenge } from 'src/model/challenge.entity';
import { EventReward } from 'src/model/event-reward.entity';

@WebSocketGateway()
@UseGuards(AdminGuard)
export class AdminGateway {
  constructor(
    private adminService: AdminService,
    private adminCallbackService: AdminCallbackService,
  ) {}

  @SubscribeMessage('requestEvents')
  async requestEvents(@CallingUser() user: User, data: RequestEventsDto) {
    const events = await this.adminService.getAllEventData();

    this.adminCallbackService.emitUpdateEventData({
      deletedIds:[],
      events: await Promise.all(
        events.map(async (ev: EventBase) => ({
          id: ev.id,
          skippingEnabled: ev.skippingEnabled,
          isDefault:ev.isDefault,
          name: ev.name,
          description: ev.description,
          rewardType: ev.rewardType,
          time: ev.time.toUTCString(),
          requiredMembers: ev.requiredMembers,
          topCount: ev.topCount,
          indexable: ev.indexable,
          challengeIds: (
            await ev.challenges.loadItems()
          ).map((ch: Challenge) => ch.id),
          rewardIds: (
            await ev.rewards.loadItems()
          ).map((rw: EventReward) => (rw.id)),
        })),
      ),
    })
  }

  @SubscribeMessage('requestChallenges')
  async requestChallenges(
    @CallingUser() user: User,
    data: RequestChallengesDto,
  ) {
    const challenges = await this.adminService.getAllChallengeData();

    this.adminCallbackService.emitUpdateChallengeData({
      deletedIds:[],
      challenges: await Promise.all(
        challenges.map(async (ch:Challenge) => ({
          id: ch.id,
          name: ch.name,
          description: ch.description,
          imageUrl: ch.imageUrl,
          latitude: ch.latitude,
          longitude: ch.longitude,
          awardingRadius: ch.awardingRadius,
          closeRadius: ch.closeRadius,
        }))
      ),
    });
  }

  @SubscribeMessage('requestRewards')
  async requestRewards(@CallingUser() user: User, data: RequestRewardsDto) {}

  @SubscribeMessage('requestAdmins')
  async requestAdmins(@CallingUser() user: User, data: RequestAdminsDto) {
    const admins = await this.adminService.getAllRequestingAdmins();
    // Only send to the requester
    this.adminCallbackService.emitUpdateAdminData({
      admins: admins.map(usr => ({
        id: usr.id,
        requesting: true,
        email: usr.email,
        superuser: usr.superuser,
      })),
    });
  }

  @SubscribeMessage('updateEvents')
  async updateEvents(@CallingUser() user: User, data: UpdateEventsDto) {
    for (const id in data.deletedIds){
      this.adminService.removeEvent(id);
    }
    for (const event of data.events){
      if ((await this.adminService.getAllEventData()).some(e => e.id === event.id)){
        this.adminService.updateEvent(event);
      }
    }
  }

  @SubscribeMessage('updateChallenges')
  async updateChallenges(
    @CallingUser() user: User,
    data: UpdateChallengesDto,
  ) {}

  @SubscribeMessage('updateRewards')
  async updateRewards(@CallingUser() user: User, data: UpdateRewardsDto) {}

  @SubscribeMessage('updateAdmins')
  async updateAdmins(@CallingUser() user: User, data: UpdateAdminsDto) {
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
}
