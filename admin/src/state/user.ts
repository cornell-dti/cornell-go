import { EventTracker } from './event-tracker';
import { EventReward } from './event-reward';
import { GroupMember } from './group-member';
import { SessionLogEntry } from './session-log-entry';

/**
 * Enum describing the type of authentication token
 */
export enum AuthType {
  /** Uses Sign in with Google token */
  GOOGLE = 'google',
  /** Uses Sign in with Apple ID token */
  APPLE = 'apple',
  /** Uses ID from device to authenticate */
  DEVICE = 'device',
  /** Cannot login through regular means */
  NONE = 'none',
}

/**
 * Entity describing a user in the database
 */
export interface User {
  id: string;

  /** Token produced by an authentication service identifying this user */
  authToken: string;

  /** The service used for authentication */
  authType: AuthType;

  username: string;

  email: string;

  /** Score calculated upon completion of each challenge added up */
  score: number;

  rewards: EventReward[];

  /** A user's membership in a group */
  groupMember: GroupMember | null;

  /** Event trackers for each event the player participated in */
  participatingEvents: EventTracker[];

  /** Actions recorded relating to this user */
  logEntries: SessionLogEntry[];
}
