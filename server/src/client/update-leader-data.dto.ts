/** DTO for user in updateLeaderData */
export interface UpdateLeaderDataUserDto {
  userId: string;
  username: string;
  score: number;
}

/** DTO for updateLeaderData */
export interface UpdateLeaderDataDto {
  eventId: string;
  offset: number;
  users: UpdateLeaderDataUserDto[];
}
