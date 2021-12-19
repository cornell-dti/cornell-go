import { Group } from './group';
import { User } from './user';

/**
 * Entity describing a user's membership in a group
 */
export interface GroupMember {
  id: number;

  isHost: boolean;

  /** Group this member is part of */
  group: Group;

  /** User this membership describes */
  user: User;
}
