import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { EventGateway } from 'src/event/event.gateway';
import { GroupGateway } from 'src/group/group.gateway';
import { UserGateway } from 'src/user/user.gateway';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { ChallengeService } from './challenge.service';
import {
  ChallengeDto,
  CompletedChallengeDto,
  RequestChallengeDataDto,
  SetCurrentChallengeDto,
  UpdateChallengeDataDto,
} from './challenge.dto';
import { GroupService } from 'src/group/group.service';
import { UserService } from 'src/user/user.service';
import { EventService } from 'src/event/event.service';
import { RequestGlobalLeaderDataDto } from 'src/user/user.dto';
import { RewardService } from 'src/reward/reward.service';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class ChallengeGateway {
  constructor(
    private clientService: ClientService,
    private challengeService: ChallengeService,
    private userService: UserService,
    private groupService: GroupService,
    private eventService: EventService,
    private rewardService: RewardService,
  ) {}

  @SubscribeMessage('requestChallengeData')
  async requestChallengeData(
    @CallingUser() user: User,
    @MessageBody() data: RequestChallengeDataDto,
  ) {
    const adminChallenges =
      await this.challengeService.getChallengesByIdsForUser(
        user,
        true,
        data.challengeIds,
      );

    const basicChallenges =
      await this.challengeService.getChallengesByIdsForUser(
        user,
        true,
        data.challengeIds,
      );

    for (const chal of adminChallenges) {
      this.clientService.subscribe(user, chal.id, true);
      await this.challengeService.emitUpdateChallengeData(
        chal,
        false,
        true,
        user,
      );
    }

    for (const chal of basicChallenges) {
      this.clientService.subscribe(user, chal.id, false);
      await this.challengeService.emitUpdateChallengeData(
        chal,
        false,
        false,
        user,
      );
    }
  }

  @SubscribeMessage('setCurrentChallenge')
  async setCurrentChallenge(
    @CallingUser() user: User,
    @MessageBody() data: SetCurrentChallengeDto,
  ) {
    if (
      await this.challengeService.setCurrentChallenge(user, data.challengeId)
    ) {
      const group = await this.groupService.getGroupForUser(user);
      const tracker = await this.eventService.getCurrentEventTrackerForUser(
        user,
      );

      await this.groupService.emitUpdateGroupData(group, false);
      await this.eventService.emitUpdateEventTracker(tracker);
    } else {
      await this.userService.emitErrorData(
        user,
        'Challenge is not valid (Challenge is not in event)',
      );
    }
  }

  @SubscribeMessage('completedChallenge')
  async completedChallenge(
    @CallingUser() user: User,
    @MessageBody() data: CompletedChallengeDto,
  ) {
    if (await this.challengeService.completeChallenge(user, data.challengeId)) {
      const group = await this.groupService.getGroupForUser(user);
      const tracker = await this.eventService.getCurrentEventTrackerForUser(
        user,
      );

      const rw = await this.challengeService.checkForReward(tracker);
      if (rw) {
        const ev = await this.eventService.getEventById(rw.eventId);
        await this.eventService.emitUpdateEventData(ev, false);
        await this.rewardService.emitUpdateRewardData(rw, false, true, user);
      }

      await this.groupService.emitUpdateGroupData(group, false);
      await this.eventService.emitUpdateEventTracker(tracker);
      await this.userService.emitUpdateUserData(user, false, false, true, user);
    } else {
      await this.userService.emitErrorData(user, 'Challenge not complete');
    }
  }

  @SubscribeMessage('requestGlobalLeaderData')
  async requestGlobalLeaderData(
    @CallingUser() user: User,
    @MessageBody() data: RequestGlobalLeaderDataDto,
  ) {
    await this.eventService.emitUpdateLeaderData(
      data.offset,
      Math.min(data.count, 1024),
      null,
      user,
    );
  }

  @SubscribeMessage('updateChallengeData')
  async updateChallengeData(
    @CallingUser() user: User,
    @MessageBody() data: UpdateChallengeDataDto,
  ) {
    if (data.deleted) {
      const challenge = await this.challengeService.getChallengeById(
        data.challenge as string,
      );

      const ev = await this.eventService.getEventById(challenge.linkedEventId);

      if (
        !(await this.eventService.hasAdminRights(
          { id: challenge.linkedEventId! },
          user,
        ))
      ) {
        await this.userService.emitErrorData(user, 'User has no admin rights');
        return;
      }

      await this.challengeService.removeChallenge(challenge.id, user);

      await this.challengeService.emitUpdateChallengeData(challenge, true);
      await this.eventService.emitUpdateEventData(ev, false);
    } else {
      const dto = data.challenge as ChallengeDto;
      if (
        !(await this.eventService.hasAdminRights(
          { id: dto.containingEventId },
          user,
        ))
      ) {
        await this.userService.emitErrorData(user, 'User has no admin rights');
        return;
      }

      const challenge = await this.challengeService.upsertChallengeFromDto(dto);
      const ev = await this.eventService.getEventById(challenge.linkedEventId);

      await this.challengeService.emitUpdateChallengeData(challenge, false);
      await this.eventService.emitUpdateEventData(ev, false);
    }
  }
}
