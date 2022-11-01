import { UserDto } from '../update-users.dto';

export interface UpdateUserDataDto {
  users: UserDto[];
  deletedIds: string[];
}
