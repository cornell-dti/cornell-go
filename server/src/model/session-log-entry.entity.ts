import {
  Entity,
  Enum,
  IdentifiedReference,
  ManyToOne,
  PrimaryKey,
  Property,
} from '@mikro-orm/core';
import { User } from './user.entity';

/**
 * Enum describing the type of entry in a session log
 */
export enum SessionLogEntryType {
  /** The user was created, placed in group {uuid} */
  USER_CREATED = 'user_created',
  /** User logged in */
  LOGIN = 'login',
  /** User logged out */
  LOGOUT = 'logout',
  /** User found place {uuid} */
  FOUND_PLACE = 'found_place',
  /** User joined group {uuid} */
  JOIN_GROUP = 'join_group',
  /** User {uuid} joined the current group */
  SOME_USER_JOINED_GROUP = 'some_user_joined_group',
  /** User {uuid} left the current group */
  SOME_USER_LEFT_GROUP = 'some_user_left_group',
  /** User left the current group and created group {uuid} */
  LEFT_GROUP = 'left_group',
  /** User changed username from {uuid} (exceptional use of the uuid field) */
  CHANGE_USERNAME = 'change_username',
  /** User kicked {uuid} from the current group */
  KICKED_MEMBER = 'kicked_member',
  /** User disbanded group and joined group {uuid} */
  DISBANDED_GROUP = 'disbanded_group',
  /** User was kicked by host and joined group {uuid} */
  KICKED_BY_HOST = 'kicked_by_host',
  /** User joined event {uuid} by inheriting group event */
  USER_JOINED_EVENT = 'user_joined_event',
  /** User joined event {uuid} by choosing event as group host */
  USER_CHOSE_EVENT = 'user_chose_event',
  /** User earned reward {uuid} */
  USER_EARNED_REWARD = 'user_earned_reward',
}

/**
 * Entity describing an entry in a session
 */
@Entity()
export class SessionLogEntry {
  @PrimaryKey()
  id!: number;

  @Enum(() => SessionLogEntryType)
  entryType!: SessionLogEntryType;

  /** Time when this entry was created */
  entryTimestamp = new Date();

  /** UUID associated with this entry type */
  @Property()
  associatedUUID?: string;

  /** User associated with this entry */
  @ManyToOne()
  user!: IdentifiedReference<User>;
}
