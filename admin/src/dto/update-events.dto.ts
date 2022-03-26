export interface EventDto {
  id: string;
  requiredMembers: number;
  skippingEnabled: boolean;
  isDefault: boolean;
  name: string;
  description: string;
  rewardType: "limited_time_event" | "perpetual";
  indexable: boolean;
  time: string;
  rewardIds: string[];
  challengeIds: string[];
}

export interface UpdateEventsDto {
  events: EventDto[];
  deletedIds: string[];
}
