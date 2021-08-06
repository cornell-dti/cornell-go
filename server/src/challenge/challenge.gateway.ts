import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { SetCurrentEventDto } from '../group/set-current-event.dto';
import { User } from '../model/user.entity';
import { CompletedChallengeDto } from './completed-challenge.dto';
import { RequestChallengeDataDto } from './request-challenge-data.dto';
import { RequestEventTrackerDataDto } from './request-event-tracker-data.dto';

@WebSocketGateway()
export class ChallengeGateway {
  constructor(private clientService: ClientService) {}

  @SubscribeMessage('requestChallengeData')
  async requestChallengeData(
    @CallingUser() user: User,
    @MessageBody() data: RequestChallengeDataDto,
  ) {}

  @SubscribeMessage('requestEventTrackerData')
  async requestEventTrackerData(
    @CallingUser() user: User,
    @MessageBody() data: RequestEventTrackerDataDto,
  ) {}

  @SubscribeMessage('setCurrentChallenge')
  async setCurrentChallenge(
    @CallingUser() user: User,
    @MessageBody() data: SetCurrentEventDto,
  ) {}

  @SubscribeMessage('completedChallenge')
  async completedChallenge(
    @CallingUser() user: User,
    @MessageBody() data: CompletedChallengeDto,
  ) {}
}
