import { forwardRef, Inject, UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { UpdateGroupDataDto } from 'src/client/update-group-data.dto';
import { EventGateway } from 'src/event/event.gateway';
import { GroupGateway } from 'src/group/group.gateway';
import { UserGateway } from 'src/user/user.gateway';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { EventService } from '../event/event.service';
import { Challenge } from '../model/challenge.entity';
import { User } from '../model/user.entity';
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
    private userGateway: UserGateway,
    private groupGateway: GroupGateway,
    private eventGateway: EventGateway,
    @Inject(forwardRef(() => EventService))
    private eventService: EventService,
  ) {}

  @SubscribeMessage('requestChallengeData')
  async requestChallengeData(
    @CallingUser() user: User,
    @MessageBody() data: RequestChallengeDataDto,
  ) {
    const completeChallenges =
      await this.challengeService.getChallengesByIdsWithPrevChallenge(
        user,
        data.challengeIds,
      );

    const completionDateFun = async (ch: Challenge) => {
      const completions = await ch.completions.loadItems();
      // TODO: this can be made more efficient if
      // getChallengesByIdsWithPrevChallenge is made more efficient
      for (const completion of completions) {
        if (completion.owner.id === user.id) {
          return completion.foundTimestamp.toISOString();
        }
      }
      return '';
    };

    this.clientService.emitUpdateChallengeData(user, {
      challenges: await Promise.all(
        completeChallenges
          .sort((a, b) => a.eventIndex - b.eventIndex)
          .map(async ch => ({
            id: ch.id,
            name: ch.name,
            description: ch.description,
            imageUrl: ch.imageUrl,
            lat: ch.latitude,
            long: ch.longitude,
            awardingRadius: ch.awardingRadius,
            closeRadius: ch.closeRadius,
            completionDate: await completionDateFun(ch),
          })),
      ),
    });

    return false;
  }

  @SubscribeMessage('setCurrentChallenge')
  async setCurrentChallenge(
    @CallingUser() user: User,
    @MessageBody() data: SetCurrentChallengeDto,
  ) {
    const group = await user.group?.load();

    const isChallengeValid = await this.eventService.isChallengeInEvent(
      data.challengeId,
      group.currentEvent.id,
    );

    if (!isChallengeValid) return false;

    const eventTracker = await this.eventService.getCurrentEventTrackerForUser(
      user,
    );

    const challenge = await this.challengeService.getChallengeById(
      data.challengeId,
    );

    const curChallenge = await eventTracker.currentChallenge.load();

    const wasCompleted = await this.challengeService.isChallengeCompletedByUser(
      user,
      challenge,
    );

    const curCompleted = await this.challengeService.isChallengeCompletedByUser(
      user,
      curChallenge,
    );

    // Is user skipping while it's allowed
    const isSkippingWhileAllowed =
      wasCompleted ||
      (await eventTracker.event.load()).skippingEnabled ||
      (!wasCompleted &&
        curCompleted &&
        challenge.eventIndex === curChallenge.eventIndex + 1);

    if (!isSkippingWhileAllowed) return false;

    eventTracker.currentChallenge.set(challenge);
    await this.eventService.saveTracker(eventTracker);

    const members = await group.members.loadItems();

    for (const mem of members) {
      this.groupGateway.requestGroupData(mem, {});
    }

    await this.eventGateway.requestEventTrackerData(user, {
      trackedEventIds: [eventTracker.event.id],
    });

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

    const group = await user.group.load();

    for (const mem of group.members) {
      await this.groupGateway.requestGroupData(mem, {});
    }

    await newTracker.completed.loadItems();

    await this.eventGateway.requestEventTrackerData(user, {
      trackedEventIds: [newTracker.event.id],
    });

    await this.requestChallengeData(user, {
      challengeIds: [data.challengeId, newTracker.currentChallenge.id],
    });

    await this.challengeService.checkForReward(newTracker);
    await this.userGateway.requestUserData(user, {});

    this.clientService.emitInvalidateData({
      userEventData: false,
      userRewardData: false,
      winnerRewardData: true,
      groupData: false,
      challengeData: false,
      leaderboardData: true,
    });
  }
}
