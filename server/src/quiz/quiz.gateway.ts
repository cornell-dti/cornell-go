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
import { CallingUser } from '../auth/calling-user.decorator';
import { UserAbility } from '../casl/user-ability.decorator';
import { AppAbility } from '../casl/casl-ability.factory';
import { PoliciesGuard } from '../casl/policy.guard';
import { User } from '@prisma/client';
import { QuizService } from './quiz.service';
import { EventService } from '../event/event.service';
import { UserService } from '../user/user.service';
import { ClientService } from '../client/client.service';
import {
  RequestQuizQuestionDto,
  ShuffleQuizQuestionDto,
  SubmitQuizAnswerDto,
  QuizQuestionDto,
  QuizResultDto,
  QuizProgressDto,
  QuizErrorDto,
  UpdateQuizQuestionDataDto,
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
@UseGuards(UserGuard, PoliciesGuard)
export class QuizGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly quizService: QuizService,
    private readonly eventService: EventService,
    private readonly userService: UserService,
    private readonly clientService: ClientService,
  ) {}

  /**
   * Handle request for a quiz question
   * Emits: quizQuestion or quizError
   */
  @SubscribeMessage('requestQuizQuestion')
  async handleRequestQuestion(
    @CallingUser() user: User,
    @MessageBody() data: RequestQuizQuestionDto,
    @ConnectedSocket() client: Socket,
  ): Promise<boolean> {
    try {
      const question = await this.quizService.getRandomQuestion(
        data.challengeId,
        user.id,
      );

      client.emit('quizQuestion', question);
      return true;
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
      return false;
    }
  }

  /**
   * Handle shuffle request for different question
   * Emits: quizQuestion or quizError
   */
  @SubscribeMessage('shuffleQuizQuestion')
  async handleShuffleQuestion(
    @CallingUser() user: User,
    @MessageBody() data: ShuffleQuizQuestionDto,
    @ConnectedSocket() client: Socket,
  ): Promise<boolean> {
    try {
      const question = await this.quizService.shuffleQuestion(
        data.challengeId,
        user.id,
        data.currentQuestionId,
      );

      client.emit('quizQuestion', question);
      return true;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error occurred';
      const errorResponse: QuizErrorDto = {
        message: errorMessage,
        code: 'INVALID_QUESTION',
      };
      client.emit('quizError', errorResponse);
      return false;
    }
  }

  /**
   * Handle quiz answer submission
   * Emits: quizResult or quizError
   */
  @SubscribeMessage('submitQuizAnswer')
  async handleSubmitAnswer(
    @CallingUser() user: User,
    @MessageBody() data: SubmitQuizAnswerDto,
    @ConnectedSocket() client: Socket,
  ): Promise<boolean> {
    try {
      const result = await this.quizService.submitAnswer(
        user.id,
        data.questionId,
        data.selectedAnswerId,
      );

      client.emit('quizResult', result);

      // Get the event tracker to get event score
      const eventTracker =
        await this.eventService.getCurrentEventTrackerForUser(user);

      // Emit updateLeaderPosition event to update leaderboards
      await this.eventService.emitUpdateLeaderPosition({
        playerId: user.id,
        newTotalScore: result.newTotalScore,
        newEventScore: eventTracker.score,
        eventId: eventTracker.eventId,
      });

      // Emit updateUserData event to update profile page
      await this.userService.emitUpdateUserData(user, false, false, user);
      return true;
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
      return false;
    }
  }

  /**
   * Handle request for quiz progress
   * Emits: quizProgress
   */
  @SubscribeMessage('getQuizProgress')
  async handleGetProgress(
    @CallingUser() user: User,
    @MessageBody() data: RequestQuizQuestionDto,
    @ConnectedSocket() client: Socket,
  ): Promise<boolean> {
    try {
      const progress = await this.quizService.getQuizProgress(
        data.challengeId,
        user.id,
      );

      client.emit('quizProgress', progress);
      return true;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error occurred';
      const errorResponse: QuizErrorDto = {
        message: errorMessage,
        code: 'INVALID_QUESTION',
      };
      client.emit('quizError', errorResponse);
      return false;
    }
  }

  // ============================================
  // Admin handlers for quiz question management
  // ============================================

  /**
   * Request all quiz questions for a challenge (admin)
   * Emits: updateQuizQuestionData for each question
   */
  @SubscribeMessage('requestQuizQuestions')
  async handleRequestQuizQuestions(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: RequestQuizQuestionDto,
  ): Promise<number> {
    const questions = await this.quizService.getQuestionsByChallenge(
      data.challengeId,
    );

    for (const question of questions) {
      await this.quizService.emitUpdateQuizQuestionData(question, false, user);
    }

    return questions.length;
  }

  /**
   * Create, update, or delete a quiz question (admin)
   * Follows the UpdateChallengeDataDto pattern
   */
  @SubscribeMessage('updateQuizQuestionData')
  async handleUpdateQuizQuestionData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: UpdateQuizQuestionDataDto,
  ): Promise<string | undefined> {
    let question = await this.quizService.getQuestionById(data.question.id);

    if (data.deleted) {
      if (
        !question ||
        !(await this.quizService.removeQuestion(ability, question.id))
      ) {
        return;
      }

      await this.quizService.emitUpdateQuizQuestionData(question, true);
    } else {
      question = await this.quizService.upsertQuestionFromDto(
        ability,
        data.question,
      );

      if (!question) {
        await this.clientService.emitErrorData(
          user,
          'Failed to upsert quiz question!',
        );
        return;
      }

      await this.quizService.emitUpdateQuizQuestionData(question, false);
    }

    return question.id;
  }
}
