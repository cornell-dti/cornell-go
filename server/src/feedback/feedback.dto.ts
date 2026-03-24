export enum FeedbackCategoryDto {
  BUG_REPORT = 'BUG_REPORT',
  SUGGESTION = 'SUGGESTION',
  GENERAL = 'GENERAL',
}

export interface SubmitFeedbackDto {
  category: FeedbackCategoryDto;
  text: string;
  rating?: boolean;
  challengeId?: string;
}

export interface FeedbackDto {
  id: string;
  createdAt: string;
  category: FeedbackCategoryDto;
  text: string;
  rating?: boolean;
  challengeId?: string;
  userId: string;
  username?: string;
  challengeName?: string;
}

export interface UpdateFeedbackDataDto {
  feedbacks: FeedbackDto[];
}
