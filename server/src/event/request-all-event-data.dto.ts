/** DTO for requestAllEventData */
export interface RequestAllEventDataDto {
  offset: number;
  count: number;
  rewardTypes: string[];
  closestToEnding: boolean;
  shortestFirst: boolean;
  skippableOnly: boolean;
}
