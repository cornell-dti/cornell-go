/** DTO for reward type */
export type RewardTypeDto = 'limited_time_event' | 'perpetual';

/** DTO for reward in updateEventData */
export interface UpdateEventDataRewardDto {
  id: string;
  description: string;
}

/** DTO for event in updateEventData */
export interface UpdateEventDataEventDto {
  id: string;
  skippingEnabled: boolean;
  name: string;
  description: string;
  rewardType: RewardTypeDto;
  time: string;
  rewards: UpdateEventDataRewardDto[];
  requiredMembers: number;
  challengeIds: string[];
}

/** DTO for updateEventData */
export interface UpdateEventDataDto {
  events: UpdateEventDataEventDto[];
  isSearch: boolean;
}
