export interface UserDto {
  id: string;
  authType: "google" | "apple" | "device" | "none";
  username: string;
  email: string;
  groupId: string;
}

export interface UpdateUsersDto {
  users: UserDto[];
  deletedIds: string[];
}
