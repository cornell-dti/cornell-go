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

  // Use sendEvent instead of sendProtected/emit... since timer events are just notifications and don't check data
  @SubscribeMessage('startChallengeTimer')
  async startChallengeTimer(
    @CallingUser() user: User,
    @MessageBody() data: StartChallengeTimerDto,
  ) {
    try {
      const timer = await this.timerService.startTimer(data.challengeId, user.id);
      await this.clientService.sendEvent([`user/${user.id}`], 'timerStarted', {
        timerId: timer.timerId,
        endTime: timer.endTime,
        challengeId: timer.challengeId,
        extensionsUsed: timer.extensionsUsed,
      });
      return timer.timerId;
    } catch (error) {
      // Send error to frontend instead of throwing
      const errorMessage = error instanceof Error ? error.message : 'Failed to start timer';
      console.error(`[TimerGateway] Error starting timer for challenge ${data.challengeId}, userId ${user.id}:`, errorMessage);
      await this.clientService.emitErrorData(user, errorMessage);
      return null;
    }
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
      data.challengeCompleted,
    );
    await this.clientService.sendEvent([`user/${user.id}`], 'timerCompleted', {
      timerId: timer.timerId,
      challengeId: timer.challengeId,
      challengeCompleted: timer.challengeCompleted,
    });
    return timer.challengeCompleted;
  }
}
