/** DTO for challenge in updateChallengeData */
export interface UpdateChallengeDataChallengeDto {
  id: string;
  name: string;
  description: string;
  imageUrl: string;
  lat: number;
  long: number;
  awardingRadius: number;
  closeRadius: number;
  completionDate: string;
}

/** DTO for updateChallengeData */
export interface UpdateChallengeDataDto {
  challenges: UpdateChallengeDataChallengeDto[];
}
