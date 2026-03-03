import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { QuizQuestion, QuizAnswer, User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ClientService } from '../client/client.service';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { accessibleBy } from '@casl/prisma';
import { Action } from '../casl/action.enum';
import {
  QuizQuestionDto,
  QuizAnswerDto,
  QuizResultDto,
  QuizProgressDto,
  UpdateQuizQuestionDataDto,
} from './quiz.dto';

@Injectable()
export class QuizService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clientService: ClientService,
    private readonly abilityFactory: CaslAbilityFactory,
  ) {}

  /**
   * Get a random unanswered question for a challenge
   * @param challengeId - Challenge to get question for
   * @param userId - User requesting the question
   * @returns Random question with shuffled answers
   */
  async getRandomQuestion(
    challengeId: string,
    userId: string,
  ): Promise<QuizQuestionDto> {
    const availableQuestions = await this.prisma.quizQuestion.findMany({
      where: {
        challengeId,
        userAnswers: {
          none: { userId },
        },
      },
      include: {
        answers: true,
      },
    });

    // Filter to only valid questions (at least 2 answers, exactly one correct)
    const validQuestions = availableQuestions.filter(q => {
      if (!q.answers || q.answers.length < 2) return false;
      const correctCount = q.answers.filter(a => a.isCorrect).length;
      return correctCount === 1;
    });

    if (validQuestions.length === 0) {
      throw new NotFoundException('No available questions for this challenge');
    }

    const randomIndex = Math.floor(Math.random() * validQuestions.length);
    const selectedQuestion = validQuestions[randomIndex];

    const shuffledAnswers = this.shuffleArray<{
      id: string;
      answerText: string;
      isCorrect?: boolean;
    }>(selectedQuestion.answers);

    return {
      id: selectedQuestion.id,
      questionText: selectedQuestion.questionText,
      answers: shuffledAnswers.map(answer => ({
        id: answer.id,
        answerText: answer.answerText,
      })),
      pointValue: selectedQuestion.pointValue,
      challengeId: selectedQuestion.challengeId,
      category: selectedQuestion.category,
    };
  }

  /**
   * Get a different question (for shuffle functionality)
   * @param challengeId - Challenge ID
   * @param userId - User ID
   * @param excludeQuestionId - Question to exclude from selection
   * @returns Different random question
   */
  async shuffleQuestion(
    challengeId: string,
    userId: string,
    excludeQuestionId?: string,
  ): Promise<QuizQuestionDto> {
    const availableQuestions = await this.prisma.quizQuestion.findMany({
      where: {
        challengeId,
        id: excludeQuestionId ? { not: excludeQuestionId } : undefined,
        userAnswers: {
          none: { userId },
        },
      },
      include: {
        answers: true,
      },
    });

    // Filter to only valid questions (at least 2 answers, exactly one correct)
    const validQuestions = availableQuestions.filter(q => {
      if (!q.answers || q.answers.length < 2) return false;
      const correctCount = q.answers.filter(a => a.isCorrect).length;
      return correctCount === 1;
    });

    if (validQuestions.length === 0) {
      throw new NotFoundException('No available questions for this challenge');
    }

    const randomIndex = Math.floor(Math.random() * validQuestions.length);
    const selectedQuestion = validQuestions[randomIndex];
    const shuffledAnswers = this.shuffleArray<{
      id: string;
      answerText: string;
      isCorrect?: boolean;
    }>(selectedQuestion.answers);

    return {
      id: selectedQuestion.id,
      questionText: selectedQuestion.questionText,
      answers: shuffledAnswers.map(answer => ({
        id: answer.id,
        answerText: answer.answerText,
      })),
      pointValue: selectedQuestion.pointValue,
      challengeId: selectedQuestion.challengeId,
      category: selectedQuestion.category,
    };
  }

  /**
   * Check if user has already answered a specific question
   * @param userId - User ID
   * @param questionId - Question ID
   * @returns Whether user has answered this question
   */
  async hasAnsweredQuestion(
    userId: string,
    questionId: string,
  ): Promise<boolean> {
    const existingAnswer = await this.prisma.userQuizAnswer.findUnique({
      where: {
        userId_questionId: {
          userId,
          questionId,
        },
      },
    });

    return !!existingAnswer;
  }

  /**
   * Validate and record user's answer
   * @param userId - User submitting answer
   * @param questionId - Question being answered
   * @param selectedAnswerId - Selected answer ID
   * @returns Result with correctness and points
   */
  async submitAnswer(
    userId: string,
    questionId: string,
    selectedAnswerId: string,
  ): Promise<QuizResultDto> {
    if (await this.hasAnsweredQuestion(userId, questionId)) {
      throw new BadRequestException('Question already answered');
    }

    const question = await this.prisma.quizQuestion.findUnique({
      where: { id: questionId },
      include: {
        answers: true,
      },
    });

    if (!question) {
      throw new NotFoundException('Question not found');
    }

    const selectedAnswer = question.answers.find(
      (a: { id: string }) => a.id === selectedAnswerId,
    );
    if (!selectedAnswer) {
      throw new BadRequestException('Invalid answer selection');
    }

    const correctAnswer = question.answers.find(
      (a: { isCorrect: any }) => a.isCorrect,
    );
    const isCorrect = selectedAnswer.isCorrect;
    const pointsEarned = isCorrect ? question.pointValue : 0;

    await this.prisma.userQuizAnswer.create({
      data: {
        userId,
        questionId,
        selectedAnswerId,
        isCorrect,
        pointsEarned,
      },
    });

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        score: {
          increment: pointsEarned,
        },
      },
    });

    return {
      isCorrect,
      pointsEarned,
      explanation: question.explanation ?? undefined,
      correctAnswerText: correctAnswer?.answerText || '',
      newTotalScore: updatedUser.score,
    };
  }

  /**
   * Get quiz progress for a challenge
   * @param challengeId - Challenge ID
   * @param userId - User ID
   * @returns Progress statistics
   */
  async getQuizProgress(
    challengeId: string,
    userId: string,
  ): Promise<QuizProgressDto> {
    const totalQuestions = await this.prisma.quizQuestion.count({
      where: { challengeId },
    });

    const answeredQuestions = await this.prisma.userQuizAnswer.count({
      where: {
        userId,
        question: {
          challengeId,
        },
      },
    });

    const totalPointsEarned = await this.prisma.userQuizAnswer.aggregate({
      where: {
        userId,
        question: {
          challengeId,
        },
      },
      _sum: {
        pointsEarned: true,
      },
    });

    return {
      challengeId,
      totalQuestions,
      answeredQuestions,
      remainingQuestions: totalQuestions - answeredQuestions,
      isComplete: answeredQuestions >= totalQuestions,
      totalPointsEarned: totalPointsEarned._sum.pointsEarned || 0,
    };
  }

  /**
   * Get available questions for a user at a challenge
   * @param challengeId - Challenge ID
   * @param userId - User ID
   * @returns Count of available questions
   */
  async getAvailableQuestionCount(
    challengeId: string,
    userId: string,
  ): Promise<number> {
    return this.prisma.quizQuestion.count({
      where: {
        challengeId,
        userAnswers: {
          none: { userId },
        },
      },
    });
  }

  /**
   * Utility function to shuffle an array
   * @param array - Array to shuffle
   * @returns Shuffled copy of array
   */
  private shuffleArray<T>(array: T[]): T[] {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
  }

  // ============================================
  // Admin methods for quiz question management
  // ============================================

  /**
   * Get all quiz questions for a challenge (with answers, for admin editing)
   * @param challengeId - Challenge ID
   * @returns Array of quiz questions with answers
   */
  async getQuestionsByChallenge(
    challengeId: string,
  ): Promise<(QuizQuestion & { answers: QuizAnswer[] })[]> {
    return await this.prisma.quizQuestion.findMany({
      where: { challengeId },
      include: { answers: true },
      orderBy: { createdAt: 'asc' },
    });
  }

  /**
   * Get a single quiz question by ID
   * @param id - Question ID
   * @returns Quiz question with answers or null
   */
  async getQuestionById(
    id: string,
  ): Promise<(QuizQuestion & { answers: QuizAnswer[] }) | null> {
    return await this.prisma.quizQuestion.findFirst({
      where: { id },
      include: { answers: true },
    });
  }

  /**
   * Create or update a quiz question with answers
   * @param ability - CASL ability for permission checking
   * @param dto - Quiz question data
   * @returns Created/updated question or null if unauthorized
   */
  async upsertQuestionFromDto(
    ability: AppAbility,
    dto: QuizQuestionDto,
  ): Promise<(QuizQuestion & { answers: QuizAnswer[] }) | null> {
    // Check if updating existing or creating new
    let question = await this.getQuestionById(dto.id);

    // Permission check: can user update the challenge that owns this question?
    const challengeId = dto.challengeId ?? question?.challengeId ?? '';
    const canUpdateChallenge =
      (await this.prisma.challenge.count({
        where: {
          AND: [
            accessibleBy(ability, Action.Update).Challenge,
            { id: challengeId },
          ],
        },
      })) > 0;

    if (!canUpdateChallenge) return null;

    if (question) {
      // Update existing question
      question = await this.prisma.quizQuestion.update({
        where: { id: question.id },
        data: {
          questionText: dto.questionText?.substring(0, 2048),
          explanation: dto.explanation?.substring(0, 2048),
          difficulty: dto.difficulty ?? 1,
          pointValue: dto.pointValue ?? 10,
          category: dto.category ?? 'HISTORICAL',
        },
        include: { answers: true },
      });

      // Handle answers update: delete old, create new
      // Note: UserQuizAnswer.selectedAnswerId is set to null automatically via onDelete: SetNull
      if (dto.answers && dto.answers.length > 0) {
        await this.prisma.quizAnswer.deleteMany({
          where: { questionId: question.id },
        });
        await this.prisma.quizAnswer.createMany({
          data: dto.answers.map(a => ({
            questionId: question!.id,
            answerText: a.answerText.substring(0, 1024),
            isCorrect: a.isCorrect ?? false,
          })),
        });
        // Refetch with new answers
        question = await this.getQuestionById(question.id);
      }
    } else {
      // Create new question
      if (!dto.challengeId) return null;

      question = await this.prisma.quizQuestion.create({
        data: {
          challengeId: dto.challengeId,
          questionText: dto.questionText?.substring(0, 2048) ?? '',
          explanation: dto.explanation?.substring(0, 2048),
          difficulty: dto.difficulty ?? 1,
          pointValue: dto.pointValue ?? 10,
          category: dto.category ?? 'HISTORICAL',
          answers: {
            create:
              dto.answers?.map(a => ({
                answerText: a.answerText.substring(0, 1024),
                isCorrect: a.isCorrect ?? false,
              })) ?? [],
          },
        },
        include: { answers: true },
      });

      console.log(`Created quiz question ${question.id}`);
    }

    return question;
  }

  /**
   * Delete a quiz question
   * @param ability - CASL ability for permission checking
   * @param questionId - Question ID to delete
   * @returns true if deleted, false if unauthorized or not found
   */
  async removeQuestion(
    ability: AppAbility,
    questionId: string,
  ): Promise<boolean> {
    const question = await this.getQuestionById(questionId);
    if (!question) return false;

    // Permission check: can user update the challenge that owns this question?
    const canUpdateChallenge =
      (await this.prisma.challenge.count({
        where: {
          AND: [
            accessibleBy(ability, Action.Update).Challenge,
            { id: question.challengeId },
          ],
        },
      })) > 0;

    if (!canUpdateChallenge) return false;

    await this.prisma.quizQuestion.delete({
      where: { id: questionId },
    });

    console.log(`Deleted quiz question ${questionId}`);
    return true;
  }

  /**
   * Emit quiz question update via WebSocket
   * @param question - Question that was updated
   * @param deleted - Whether the question was deleted
   * @param target - Optional specific user to send to
   */
  async emitUpdateQuizQuestionData(
    question: QuizQuestion & { answers: QuizAnswer[] },
    deleted: boolean,
    target?: User,
  ) {
    const dto: UpdateQuizQuestionDataDto = {
      question: deleted ? { id: question.id } : this.dtoForQuestion(question),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateQuizQuestionData',
      target ?? question.challengeId,
      dto,
      {
        id: question.id,
        dtoField: 'question',
        subject: 'QuizQuestion',
        prismaStore: this.prisma.quizQuestion,
      },
    );
  }

  /**
   * Convert question entity to DTO
   * @param question - Question with answers
   * @returns QuizQuestionDto
   */
  dtoForQuestion(
    question: QuizQuestion & { answers: QuizAnswer[] },
  ): QuizQuestionDto {
    return {
      id: question.id,
      challengeId: question.challengeId,
      questionText: question.questionText,
      explanation: question.explanation ?? undefined,
      difficulty: question.difficulty,
      pointValue: question.pointValue,
      category: question.category,
      answers: question.answers.map(a => ({
        id: a.id,
        answerText: a.answerText,
        isCorrect: a.isCorrect,
      })),
    };
  }
}
