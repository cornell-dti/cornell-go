export interface ChallengeDto {
  id: string;
  name: string;
  description: string;
  imageUrl: string;
  latitude: number;
  longitude: number;
  awardingRadius: number;
  closeRadius: number;
}

export interface UpdateChallengesDto {
  challenges: ChallengeDto[];
  deletedIds: string[];
}
