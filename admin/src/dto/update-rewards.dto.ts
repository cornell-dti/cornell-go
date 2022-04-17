export interface RewardDto {
  id: string;
  description: string;
  redeemInfo: string;
  containingEventId: string;
  claimingUserId: string;
}

export interface UpdateRewardsDto {
  rewards: RewardDto[];
  deletedIds: string[];
}
