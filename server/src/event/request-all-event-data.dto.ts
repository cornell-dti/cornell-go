/** DTO for requestAllEventData */
export interface RequestAllEventDataDto {
  accessToken: string;
  offset: number;
  count: number;
  rewardTypes: string[];
  closestToEnding: boolean;
  shortestFirst: boolean;
  skippableOnly: boolean;
}
