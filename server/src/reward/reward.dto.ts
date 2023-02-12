/** DTO for requestRewardData */
export interface RequestRewardDataDto {
  rewardIds: string[];
}

/** DTO for reward in updateEventData */
export interface RewardDto {
  id: string;
  eventId: string;
  description: string;
  userId?: string;
  redeemInfo?: string;
  isRedeemed?: boolean;
}

export interface UpdateRewardDataDto {
  reward: RewardDto | string;
  deleted: boolean;
}
