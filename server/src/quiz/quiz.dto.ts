// handles all data structures for quiz functions

/** Request a quiz question for a specific challenge */
export interface RequestQuizQuestionDto {
  challengeId: string;
}

/** Request to shuffle/get different question */
export interface ShuffleQuizQuestionDto {
  challengeId: string;
  currentQuestionId?: string;
}

/** Quiz answer - isCorrect is optional (omitted for users, included for admin) */
export interface QuizAnswerDto {
  id?: string;
  answerText: string;
  isCorrect?: boolean;
}

/** Quiz question - all fields optional for flexibility */
export interface QuizQuestionDto {
  id: string;
  challengeId?: string;
  questionText?: string;
  explanation?: string;
  difficulty?: number;
  pointValue?: number;
  category?: string;
  answers?: QuizAnswerDto[];
}

/** User's answer submission */
export interface SubmitQuizAnswerDto {
  questionId: string;
  selectedAnswerId: string;
}

/** Result of a quiz answer submission */
export interface QuizResultDto {
  isCorrect: boolean;
  pointsEarned: number;
  explanation?: string;
  correctAnswerText: string;
  newTotalScore: number;
}

/** Progress tracking for quiz at a challenge location */
export interface QuizProgressDto {
  challengeId: string;
  totalQuestions: number;
  answeredQuestions: number;
  remainingQuestions: number;
  isComplete: boolean;
  totalPointsEarned: number;
}

/** Error response for quiz operations */
export interface QuizErrorDto {
  message: string;
  code:
    | 'NO_QUESTIONS'
    | 'ALREADY_ANSWERED'
    | 'INVALID_QUESTION'
    | 'INVALID_ANSWER';
}

/** Update/delete quiz question (follows UpdateChallengeDataDto pattern) */
export interface UpdateQuizQuestionDataDto {
  question: QuizQuestionDto;
  deleted: boolean;
}
