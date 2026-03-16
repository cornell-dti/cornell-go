export enum FeedbackCategoryDto {
  BUG_REPORT = 'BUG_REPORT',
  SUGGESTION = 'SUGGESTION',
  GENERAL = 'GENERAL',
}

export interface SubmitFeedbackDto {
  category: FeedbackCategoryDto;
  text: string;
  rating?: number;
  challengeId?: string;
}
