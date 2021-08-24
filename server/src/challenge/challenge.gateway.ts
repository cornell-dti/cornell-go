import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { EventService } from '../event/event.service';
import { User } from '../model/user.entity';
import { UserService } from '../user/user.service';
import { ChallengeService } from './challenge.service';
import { CompletedChallengeDto } from './completed-challenge.dto';
import { RequestChallengeDataDto } from './request-challenge-data.dto';
import { RequestEventTrackerDataDto } from './request-event-tracker-data.dto';
import { SetCurrentChallengeDto } from './set-current-challenge.dto';

@WebSocketGateway()
export class ChallengeGateway {
  constructor(
    private clientService: ClientService,
    private challengeService: ChallengeService,
    private userService: UserService,
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
        lat: ch.location.coordinates[1],
        long: ch.location.coordinates[0],
        awardingRadius: ch.awardingRadius,
        closeRadius: ch.closeRadius,
        completionDate: ch.completions[0]?.foundTimestamp?.toUTCString() ?? '',
      })),
    });

    return true;
  }

  @SubscribeMessage('setCurrentChallenge')
  async setCurrentChallenge(
    @CallingUser() user: User,
    @MessageBody() data: SetCurrentChallengeDto,
  ) {
    const basicUser = await this.userService.loadBasic(user);

    const isChallengeValid = await this.eventService.isChallengeInEvent(
      data.challengeId,
      basicUser.groupMember?.group.currentEvent.id ?? '',
    );

    if (!isChallengeValid) return false;
  }

  @SubscribeMessage('completedChallenge')
  async completedChallenge(
    @CallingUser() user: User,
    @MessageBody() data: CompletedChallengeDto,
  ) {}
}
