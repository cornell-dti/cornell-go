/** DTO for event data in updateRewardData */
export interface UpdateRewardDataRewardDto {
  eventId: string;
  description: string;
  redeemInfo: string;
  isRedeemed: boolean;
}

/** DTO for updateRewardData */
export interface UpdateRewardDataDto {
  rewards: UpdateRewardDataRewardDto[];
}
