export interface UserDto {
  id: string;
  username: string;
  email: string;
  groupId: string;
}

export interface UpdateUsersDto {
  users: UserDto[];
  deletedIds: string[];
}
