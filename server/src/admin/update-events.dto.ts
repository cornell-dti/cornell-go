export interface EventDto {
  id: string;
  requiredMembers: number;
  skippingEnabled: boolean;
  isDefault: boolean;
  name: string;
  description: string;
  rewardType:
    | 'limited_time_event'
    | 'win_on_completion'
    | 'race_to_win'
    | 'no_rewards';
  indexable: boolean;
  time: string;
  topCount: number;
  rewardIds: string[];
  challengeIds: string[];
}

export interface UpdateEventsDto {
  events: EventDto[];
  deletedIds: string[];
}
