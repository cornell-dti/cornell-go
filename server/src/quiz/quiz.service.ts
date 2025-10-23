import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { 
  QuizQuestionDto, 
  QuizResultDto, 
  QuizProgressDto,
} from './quiz.dto';

@Injectable()
export class QuizService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get a random unanswered question for a challenge
   * @param challengeId - Challenge to get question for
   * @param userId - User requesting the question
   * @returns Random question with shuffled answers
   */
  async getRandomQuestion(challengeId: string, userId: string): Promise<QuizQuestionDto> {
    const availableQuestions = await this.prisma.quizQuestion.findMany({
      where: {
        challengeId,
        userAnswers: {
          none: { userId }
        }
      },
      include: {
        answers: true
      }
    });

    if (availableQuestions.length === 0) {
      throw new NotFoundException('No available questions for this challenge');
    }

    const randomIndex = Math.floor(Math.random() * availableQuestions.length);
    const selectedQuestion = availableQuestions[randomIndex];

    const shuffledAnswers = this.shuffleArray<{id: string, answerText: string, isCorrect?: boolean}>(selectedQuestion.answers);

    return {
      id: selectedQuestion.id,
      questionText: selectedQuestion.questionText,
      answers: shuffledAnswers.map(answer => ({
        id: answer.id,
        answerText: answer.answerText
      })),
      pointValue: selectedQuestion.pointValue,
      challengeId: selectedQuestion.challengeId
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
    excludeQuestionId?: string
  ): Promise<QuizQuestionDto> {
    const availableQuestions = await this.prisma.quizQuestion.findMany({
      where: {
        challengeId,
        id: excludeQuestionId ? { not: excludeQuestionId } : undefined,
        userAnswers: {
          none: { userId }
        }
      },
      include: {
        answers: true
      }
    });

    if (availableQuestions.length === 0) {
      return this.getRandomQuestion(challengeId, userId);
    }

    const randomIndex = Math.floor(Math.random() * availableQuestions.length);
    const selectedQuestion = availableQuestions[randomIndex];
    const shuffledAnswers = this.shuffleArray<{id: string, answerText: string, isCorrect?: boolean}>(selectedQuestion.answers);

    return {
      id: selectedQuestion.id,
      questionText: selectedQuestion.questionText,
      answers: shuffledAnswers.map(answer => ({
        id: answer.id,
        answerText: answer.answerText
      })),
      pointValue: selectedQuestion.pointValue,
      challengeId: selectedQuestion.challengeId
    };
  }

  /**
   * Check if user has already answered a specific question
   * @param userId - User ID
   * @param questionId - Question ID
   * @returns Whether user has answered this question
   */
  async hasAnsweredQuestion(userId: string, questionId: string): Promise<boolean> {
    const existingAnswer = await this.prisma.userQuizAnswer.findUnique({
      where: {
        userId_questionId: {
          userId,
          questionId
        }
      }
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
    selectedAnswerId: string
  ): Promise<QuizResultDto> {
    if (await this.hasAnsweredQuestion(userId, questionId)) {
      throw new BadRequestException('Question already answered');
    }

    const question = await this.prisma.quizQuestion.findUnique({
      where: { id: questionId },
      include: {
        answers: true
      }
    });

    if (!question) {
      throw new NotFoundException('Question not found');
    }

    const selectedAnswer = question.answers.find((a: { id: string; }) => a.id === selectedAnswerId);
    if (!selectedAnswer) {
      throw new BadRequestException('Invalid answer selection');
    }

    const correctAnswer = question.answers.find((a: { isCorrect: any; }) => a.isCorrect);
    const isCorrect = selectedAnswer.isCorrect;
    const pointsEarned = isCorrect ? question.pointValue : 0;

    await this.prisma.userQuizAnswer.create({
      data: {
        userId,
        questionId,
        selectedAnswerId,
        isCorrect,
        pointsEarned
      }
    });

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        score: {
          increment: pointsEarned
        }
      }
    });

    return {
      isCorrect,
      pointsEarned,
      explanation: question.explanation,
      correctAnswerText: correctAnswer?.answerText || '',
      newTotalScore: updatedUser.score
    };
  }

  /**
   * Get quiz progress for a challenge
   * @param challengeId - Challenge ID
   * @param userId - User ID
   * @returns Progress statistics
   */
  async getQuizProgress(challengeId: string, userId: string): Promise<QuizProgressDto> {
    const totalQuestions = await this.prisma.quizQuestion.count({
      where: { challengeId }
    });

    const answeredQuestions = await this.prisma.userQuizAnswer.count({
      where: {
        userId,
        question: {
          challengeId
        }
      }
    });

    const totalPointsEarned = await this.prisma.userQuizAnswer.aggregate({
      where: {
        userId,
        question: {
          challengeId
        }
      },
      _sum: {
        pointsEarned: true
      }
    });

    return {
      challengeId,
      totalQuestions,
      answeredQuestions,
      remainingQuestions: totalQuestions - answeredQuestions,
      isComplete: answeredQuestions >= totalQuestions,
      totalPointsEarned: totalPointsEarned._sum.pointsEarned || 0
    };
  }

  /**
   * Get available questions for a user at a challenge
   * @param challengeId - Challenge ID
   * @param userId - User ID
   * @returns Count of available questions
   */
  async getAvailableQuestionCount(challengeId: string, userId: string): Promise<number> {
    return this.prisma.quizQuestion.count({
      where: {
        challengeId,
        userAnswers: {
          none: { userId }
        }
      }
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
}