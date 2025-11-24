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
import {
  ExtendTimerDto,
  StartChallengeTimerDto,
  TimerCompletedDto,
} from './timer.dto';
import { PoliciesGuard } from '../casl/policy.guard';
import { TimerService } from './timer.service';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class TimerGateway {
  constructor(
    private clientService: ClientService,
    private timerService: TimerService,
  ) {}

  //use sendEvent instead of sendProtected/emit... since timer events are just notifications and dont check data
  @SubscribeMessage('startChallengeTimer')
  async startChallengeTimer(
    @CallingUser() user: User,
    @MessageBody() data: StartChallengeTimerDto,
  ) {
    // console.log(`[TimerGateway] startChallengeTimer called for challengeId=${data.challengeId}, userId=${user.id}`);
    const timer = await this.timerService.startTimer(data.challengeId, user.id);
    // console.log(`[TimerGateway] Timer created: timerId=${timer.timerId}, endTime=${timer.endTime}`);
    await this.clientService.sendEvent([`user/${user.id}`], 'timerStarted', {
      timerId: timer.timerId,
      endTime: timer.endTime,
      challengeId: timer.challengeId,
    });
    // console.log(`[TimerGateway] timerStarted event sent to user/${user.id}`);
    return timer.timerId;
  }

  @SubscribeMessage('extendTimer')
  async extendTimer(
    @CallingUser() user: User,
    @MessageBody() data: ExtendTimerDto,
  ) {
    try {
      const timer = await this.timerService.extendTimer(
        data.challengeId,
        user.id,
      );
      await this.clientService.sendEvent([`user/${user.id}`], 'timerExtended', {
        timerId: timer.timerId,
        challengeId: timer.challengeId,
        newEndTime: timer.newEndTime,
        extensionsUsed: timer.extensionsUsed,
      });
      return timer.timerId;
    } catch (error) {
      // Send error to frontend instead of throwing
      const errorMessage = error instanceof Error ? error.message : 'Failed to extend timer';
      await this.clientService.emitErrorData(user, errorMessage);
      return null;
    }
  }

  @SubscribeMessage('completeTimer')
  async completeTimer(
    @CallingUser() user: User,
    @MessageBody() data: TimerCompletedDto,
  ) {
    const timer = await this.timerService.completeTimer(
      data.challengeId,
      user.id,
    );
    await this.clientService.sendEvent([`user/${user.id}`], 'timerCompleted', {
      timerId: timer.timerId,
      challengeId: timer.challengeId,
      challengeCompleted: timer.challengeCompleted,
    });
    return timer.challengeCompleted;
  }
}
