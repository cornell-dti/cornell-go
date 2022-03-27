import { RewardDto } from "./update-rewards.dto";

export interface UpdateRewardDataDto {
  rewards: RewardDto[];
  deletedIds: string[];
}
