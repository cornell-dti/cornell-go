import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { UseGuards } from '@nestjs/common';
import { User } from '@prisma/client';
import { UserGuard } from '../auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { FeedbackService } from './feedback.service';
import { SubmitFeedbackDto } from './feedback.dto';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class FeedbackGateway {
  constructor(private readonly feedbackService: FeedbackService) {}

  @SubscribeMessage('submitFeedback')
  async handleSubmitFeedback(
    @CallingUser() user: User,
    @MessageBody() data: SubmitFeedbackDto,
    @ConnectedSocket() client: Socket,
  ): Promise<boolean> {
    try {
      await this.feedbackService.createFeedback(user.id, data);
      return true;
    } catch (error) {
      console.error('Failed to submit feedback:', error);
      return false;
    }
  }

  @SubscribeMessage('requestFeedbackData')
  async handleRequestFeedbackData(
    @CallingUser() user: User,
    @ConnectedSocket() client: Socket,
  ): Promise<boolean> {
    if (!user.administrator) {
      return false;
    }

    const feedbacks = await this.feedbackService.getAllFeedback();
    client.emit('updateFeedbackData', { feedbacks });
    return true;
  }
}
