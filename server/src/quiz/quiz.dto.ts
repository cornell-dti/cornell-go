export interface RequestQuizQuestionDto {
  challengeId: string;
}

export interface ShuffleQuizQuestionDto {
  challengeId: string;
  currentQuestionId?: string;
}

export interface QuizAnswerOptionDto {
  id: string;
  answerText: string;
}

export interface QuizQuestionDto {
  id: string;
  questionText: string;
  answers: QuizAnswerOptionDto[];
  pointValue: number;
  challengeId: string;
}

export interface SubmitQuizAnswerDto {
  questionId: string;
  selectedAnswerId: string;
}

export interface QuizResultDto {
  isCorrect: boolean;
  pointsEarned: number;
  explanation?: string;
  correctAnswerText: string;
  newTotalScore: number;
}

export interface QuizProgressDto {
  challengeId: string;
  totalQuestions: number;
  answeredQuestions: number;
  remainingQuestions: number;
  isComplete: boolean;
  totalPointsEarned: number;
}

export interface QuizErrorDto {
  message: string;
  code: 'NO_QUESTIONS' | 'ALREADY_ANSWERED' | 'INVALID_QUESTION' | 'INVALID_ANSWER';
}