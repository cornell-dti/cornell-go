import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { UserGuard } from '../auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { ChallengeService } from './challenge.service';
import {
  CompletedChallengeDto,
  RequestChallengeDataDto,
  SetCurrentChallengeDto,
  UpdateChallengeDataDto,
} from './challenge.dto';
import { GroupService } from '../group/group.service';
import { UserService } from '../user/user.service';
import { EventService } from '../event/event.service';
import { RequestGlobalLeaderDataDto } from '../user/user.dto';
import { PoliciesGuard } from '../casl/policy.guard';
import { UserAbility } from '../casl/user-ability.decorator';
import { AppAbility } from '../casl/casl-ability.factory';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class ChallengeGateway {
  constructor(
    private clientService: ClientService,
    private challengeService: ChallengeService,
    private userService: UserService,
    private groupService: GroupService,
    private eventService: EventService,
  ) {}

  /**
   * Subscribes and emits the information of the requested challenges
   *
   * @param user the calling user
   * @param data array of challenges to return
   */
  @SubscribeMessage('requestChallengeData')
  async requestChallengeData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: RequestChallengeDataDto,
  ) {
    const challenges = await this.challengeService.getChallengesByIdsForAbility(
      ability,
      data.challenges,
    );

    for (const chal of challenges) {
      await this.challengeService.emitUpdateChallengeData(chal, false, user);
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
      await this.clientService.emitErrorData(
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

      await this.groupService.emitUpdateGroupData(group, false);
      await this.eventService.emitUpdateEventTracker(tracker);
      await this.userService.emitUpdateUserData(user, false, true, user);
    } else {
      await this.clientService.emitErrorData(user, 'Challenge not complete');
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
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: UpdateChallengeDataDto,
  ) {
    const challenge = await this.challengeService.getChallengeById(
      data.challenge.id,
    );

    if (
      (!challenge && ability.cannot(Action.Create, 'Challenge')) ||
      (challenge &&
        ability.cannot(Action.Manage, subject('Challenge', challenge)))
    ) {
      await this.clientService.emitErrorData(
        user,
        'Permission denied for challenge update!',
      );
      return;
    }

    if (data.deleted && challenge) {
      const ev = (await this.eventService.getEventById(
        challenge.linkedEventId ?? '',
      ))!;
      await this.challengeService.removeChallenge(ability, challenge.id);

      await this.challengeService.emitUpdateChallengeData(challenge, true);
      await this.eventService.emitUpdateEventData(ev, false);
    } else {
      const challenge = await this.challengeService.upsertChallengeFromDto(
        ability,
        data.challenge,
      );

      if (!challenge) return;

      if (challenge.linkedEventId) {
        const ev = (await this.eventService.getEventById(
          challenge.linkedEventId,
        ))!;
        await this.clientService.subscribe(user, challenge.id);
        await this.challengeService.emitUpdateChallengeData(challenge, false);
        await this.eventService.emitUpdateEventData(ev, false);
      }
    }
  }
}
