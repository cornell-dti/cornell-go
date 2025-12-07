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

/** Individual answer option for a quiz question */
export interface QuizAnswerOptionDto {
  id: string;
  answerText: string;
}

/** Complete quiz question with shuffled answer options */
export interface QuizQuestionDto {
  id: string;
  questionText: string;
  answers: QuizAnswerOptionDto[];
  pointValue: number;
  challengeId: string;
  category: string;
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
