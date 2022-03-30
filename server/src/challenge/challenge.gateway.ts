import { forwardRef, Inject, UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { UpdateGroupDataDto } from 'src/client/update-group-data.dto';
import { UpdateRewardDataDto } from 'src/client/update-reward-data.dto';
import {
  UpdateUserDataAuthTypeDto,
  UpdateUserDataDto,
} from 'src/client/update-user-data.dto';
import { EventReward } from 'src/model/event-reward.entity';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { EventService } from '../event/event.service';
import { User } from '../model/user.entity';
import { UserService } from '../user/user.service';
import { ChallengeService } from './challenge.service';
import { CompletedChallengeDto } from './completed-challenge.dto';
import { RequestChallengeDataDto } from './request-challenge-data.dto';
import { SetCurrentChallengeDto } from './set-current-challenge.dto';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class ChallengeGateway {
  constructor(
    private clientService: ClientService,
    private challengeService: ChallengeService,
    private userService: UserService,
    @Inject(forwardRef(() => EventService))
    private eventService: EventService,
  ) {}

  @SubscribeMessage('requestChallengeData')
  async requestChallengeData(
    @CallingUser() user: User,
    @MessageBody() data: RequestChallengeDataDto,
  ) {
    const challengeEntities =
      await this.challengeService.getChallengesByIdsWithPrevChallenge(
        user,
        data.challengeIds,
      );

    this.clientService.emitUpdateChallengeData(user, {
      challenges: challengeEntities.map(ch => ({
        id: ch.id,
        name: ch.name,
        description: ch.description,
        imageUrl: ch.imageUrl,
        lat: ch.latitude,
        long: ch.longitude,
        awardingRadius: ch.awardingRadius,
        closeRadius: ch.closeRadius,
        completionDate: ch.completions[0]?.foundTimestamp?.toUTCString() ?? '',
      })),
    });

    return false;
  }

  @SubscribeMessage('setCurrentChallenge')
  async setCurrentChallenge(
    @CallingUser() user: User,
    @MessageBody() data: SetCurrentChallengeDto,
  ) {
    const groupMember = await user.groupMember?.load();
    const group = await groupMember?.group.load();

    const isChallengeValid = await this.eventService.isChallengeInEvent(
      data.challengeId,
      group?.currentEvent.id ?? '',
    );

    if (!isChallengeValid) return false;

    const eventTracker = await this.eventService.getCurrentEventTrackerForUser(
      user,
    );

    const challenge = await this.challengeService.getChallengeById(
      data.challengeId,
    );

    const curChallenge = await eventTracker.currentChallenge.load();

    // Is user switching to or from the star challenge
    const isStarChallengeAffected =
      challenge.eventIndex === 9999 || curChallenge.eventIndex === 9999;

    // Is user skipping while it's allowed
    const isSkippingWhileAllowed =
      curChallenge.eventIndex < challenge.eventIndex &&
      ((await eventTracker.event.load()).skippingEnabled ||
        this.challengeService.isChallengeCompletedByUser(user, challenge));

    if (isStarChallengeAffected || isSkippingWhileAllowed) return false;

    eventTracker.currentChallenge.set(challenge);
    await this.eventService.saveTracker(eventTracker);

    const updateData: UpdateGroupDataDto = {
      curEventId: group?.currentEvent.id ?? '',
      members: [
        {
          id: user.id,
          name: user.username,
          points: user.score,
          host: groupMember?.isHost ?? false,
          curChallengeId: data.challengeId,
        },
      ],
      removeListedMembers: false,
    };

    for (const mem of group?.members ?? []) {
      const member = await mem.user.load();
      this.clientService.emitUpdateGroupData(member, updateData);
    }

    return false;
  }

  @SubscribeMessage('completedChallenge')
  async completedChallenge(
    @CallingUser() user: User,
    @MessageBody() data: CompletedChallengeDto,
  ) {
    const newTracker = await this.challengeService.completeChallenge(
      user,
      data.challengeId,
    );

    const groupMember = await user.groupMember?.load();
    const group = await groupMember?.group.load();

    const updateData: UpdateGroupDataDto = {
      curEventId: group?.currentEvent.id ?? '',
      members: [
        {
          id: user.id,
          name: user.username,
          points: user.score,
          host: groupMember?.isHost ?? false,
          curChallengeId: newTracker.currentChallenge.id,
        },
      ],
      removeListedMembers: false,
    };

    for (const mem of group?.members ?? []) {
      const member = await mem.user.load();
      this.clientService.emitUpdateGroupData(member, updateData);
    }
    const event = await newTracker.event.load();
    const newReward = await this.challengeService.checkForReward(
      user,
      event,
      newTracker,
    );

    if (newReward !== null) {
      const participatingEvents = await user.participatingEvents.loadItems();
      const userRewards = await user.rewards.loadItems();
      const updatedUser: UpdateUserDataDto = {
        id: user.id,
        username: user.username,
        score: user.score,
        groupId: group?.id ?? '',
        rewardIds: userRewards.concat(newReward).map(reward => reward.id), //Add reward to user.rewards,
        trackedEventIds: participatingEvents.map(ev => ev.id),
        ignoreIdLists: false,
        authType: user.authType as UpdateUserDataAuthTypeDto,
      };
      this.clientService.emitUpdateUserData(user, updatedUser);

      const rewards = userRewards.concat(newReward).map(reward => ({
        eventId: reward.containingEvent.id,
        description: reward.rewardDescription,
        redeemInfo: reward.rewardRedeemInfo,
        isRedeemed: reward.isRedeemed,
      }));
      const updatedRewards: UpdateRewardDataDto = {
        rewards: rewards,
      };
      this.clientService.emitUpdateRewardData(user, updatedRewards);
    }

    return true;
    /**
     * TODO:
     * Create PrevChallenge and associate with user
     * Progress the user to the next challenge (if possible)
     * Reward player upon completion of last challenge (if conditions met)
     * If conditions involve other players, check for reward for all players
     *
     */
  }
}
