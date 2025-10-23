import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards } from '@nestjs/common';
import { UserGuard } from '../auth/jwt-auth.guard';
import { QuizService } from './quiz.service';
import {
  RequestQuizQuestionDto,
  ShuffleQuizQuestionDto,
  SubmitQuizAnswerDto,
  QuizQuestionDto,
  QuizResultDto,
  QuizProgressDto,
  QuizErrorDto,
} from './quiz.dto';

/**
 * WebSocket gateway for real-time quiz interactions
 * Handles question requests, shuffling, and answer submissions
 */
@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
@UseGuards(UserGuard)
export class QuizGateway {
  @WebSocketServer()
  server!: Server;

  constructor(private readonly quizService: QuizService) {}

  /**
   * Handle request for a quiz question
   * Emits: quizQuestion or quizError
   */
  @SubscribeMessage('requestQuizQuestion')
  async handleRequestQuestion(
    @MessageBody() data: RequestQuizQuestionDto,
    @ConnectedSocket() client: Socket,
  ): Promise<void> {
    try {
      const user = (client as any).data?._authenticatedUserEntity;
      const userId = user?.id;

      if (!userId) {
        throw new Error('User not authenticated');
      }

      const question = await this.quizService.getRandomQuestion(
        data.challengeId,
        userId,
      );

      client.emit('quizQuestion', question);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error occurred';
      const errorResponse: QuizErrorDto = {
        message: errorMessage,
        code: errorMessage.includes('No available questions')
          ? 'NO_QUESTIONS'
          : 'INVALID_QUESTION',
      };
      client.emit('quizError', errorResponse);
    }
  }

  /**
   * Handle shuffle request for different question
   * Emits: quizQuestion or quizError
   */
  @SubscribeMessage('shuffleQuizQuestion')
  async handleShuffleQuestion(
    @MessageBody() data: ShuffleQuizQuestionDto,
    @ConnectedSocket() client: Socket,
  ): Promise<void> {
    try {
      const user = (client as any).data?._authenticatedUserEntity;
      const userId = user?.id;

      if (!userId) {
        throw new Error('User not authenticated');
      }

      const question = await this.quizService.shuffleQuestion(
        data.challengeId,
        userId,
        data.currentQuestionId,
      );

      client.emit('quizQuestion', question);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error occurred';
      const errorResponse: QuizErrorDto = {
        message: errorMessage,
        code: 'INVALID_QUESTION',
      };
      client.emit('quizError', errorResponse);
    }
  }

  /**
   * Handle quiz answer submission
   * Emits: quizResult or quizError
   */
  @SubscribeMessage('submitQuizAnswer')
  async handleSubmitAnswer(
    @MessageBody() data: SubmitQuizAnswerDto,
    @ConnectedSocket() client: Socket,
  ): Promise<void> {
    try {
      const user = (client as any).data?._authenticatedUserEntity;
      const userId = user?.id;

      if (!userId) {
        throw new Error('User not authenticated');
      }

      const result = await this.quizService.submitAnswer(
        userId,
        data.questionId,
        data.selectedAnswerId,
      );

      client.emit('quizResult', result);
      this.server.emit('scoreUpdate', {
        userId,
        newScore: result.newTotalScore,
      });
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error occurred';
      let errorCode: QuizErrorDto['code'] = 'INVALID_ANSWER';

      if (errorMessage.includes('already answered')) {
        errorCode = 'ALREADY_ANSWERED';
      } else if (errorMessage.includes('not found')) {
        errorCode = 'INVALID_QUESTION';
      }

      const errorResponse: QuizErrorDto = {
        message: errorMessage,
        code: errorCode,
      };
      client.emit('quizError', errorResponse);
    }
  }

  /**
   * Handle request for quiz progress
   * Emits: quizProgress
   */
  @SubscribeMessage('getQuizProgress')
  async handleGetProgress(
    @MessageBody() data: { challengeId: string },
    @ConnectedSocket() client: Socket,
  ): Promise<void> {
    try {
      const user = (client as any).data?._authenticatedUserEntity;
      const userId = user?.id;

      if (!userId) {
        throw new Error('User not authenticated');
      }

      const progress = await this.quizService.getQuizProgress(
        data.challengeId,
        userId,
      );

      client.emit('quizProgress', progress);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error occurred';
      const errorResponse: QuizErrorDto = {
        message: errorMessage,
        code: 'INVALID_QUESTION',
      };
      client.emit('quizError', errorResponse);
    }
  }
}
