export interface RewardDto {
  id: string;
  description: string;
  redeemInfo: string;
}

export interface UpdateRewardsDto {
  rewards: RewardDto[];
}
