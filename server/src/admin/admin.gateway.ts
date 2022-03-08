import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { CallingUser } from 'src/auth/calling-user.decorator';
import { AdminGuard } from 'src/auth/jwt-auth.guard';
import { User } from 'src/model/user.entity';
import { RequestAdminsDto } from './request-admins.dto';
import { RequestChallengesDto } from './request-challenges.dto';
import { RequestEventsDto } from './request-events.dto';
import { RequestRewardsDto } from './request-rewards.dto';
import { UpdateAdminsDto } from './update-admins.dto';
import { UpdateChallengesDto } from './update-challenges.dto';
import { UpdateEventsDto } from './update-events.dto';
import { UpdateRewardsDto } from './update-rewards.dto';

@WebSocketGateway()
@UseGuards(AdminGuard)
export class AdminGateway {
  @SubscribeMessage('requestEvents')
  async requestEvents(@CallingUser() user: User, data: RequestEventsDto) {}

  @SubscribeMessage('requestChallenges')
  async requestChallenges(
    @CallingUser() user: User,
    data: RequestChallengesDto,
  ) {}

  @SubscribeMessage('requestRewards')
  async requestRewards(@CallingUser() user: User, data: RequestRewardsDto) {}

  @SubscribeMessage('requestAdmins')
  async requestAdmins(@CallingUser() user: User, data: RequestAdminsDto) {}

  @SubscribeMessage('updateEvents')
  async updateEvents(@CallingUser() user: User, data: UpdateEventsDto) {}

  @SubscribeMessage('updateChallenges')
  async updateChallenges(
    @CallingUser() user: User,
    data: UpdateChallengesDto,
  ) {}

  @SubscribeMessage('updateRewards')
  async updateRewards(@CallingUser() user: User, data: UpdateRewardsDto) {}

  @SubscribeMessage('updateAdmins')
  async updateAdmins(@CallingUser() user: User, data: UpdateAdminsDto) {}
}
