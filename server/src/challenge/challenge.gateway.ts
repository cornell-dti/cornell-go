import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { EventGateway } from 'src/event/event.gateway';
import { GroupGateway } from 'src/group/group.gateway';
import { UserGateway } from 'src/user/user.gateway';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
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
            completionDate: await this.challengeService.getUserCompletionDate(
              user,
              ch,
            ),
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
    const [ev, mems] = await this.challengeService.setCurrentChallenge(
      user,
      data.challengeId,
    );

    for (const mem of mems) {
      this.groupGateway.requestGroupData(mem, {});
    }

    await this.eventGateway.requestEventTrackerData(user, {
      trackedEventIds: [ev.id],
    });

    return false;
  }

  @SubscribeMessage('completedChallenge')
  async completedChallenge(
    @CallingUser() user: User,
    @MessageBody() data: CompletedChallengeDto,
  ) {
    const [newTracker, mems] = await this.challengeService.completeChallenge(
      user,
      data.challengeId,
    );

    for (const mem of mems) {
      await this.groupGateway.requestGroupData(mem, {});
    }

    await this.eventGateway.requestEventTrackerData(user, {
      trackedEventIds: [newTracker.eventId],
    });

    await this.requestChallengeData(user, {
      challengeIds: [data.challengeId, newTracker.curChallengeId],
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
