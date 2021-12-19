import { Challenge } from './challenge';
import { User } from './user';

/**
 * Entity describing a completed challenge
 */
export interface PrevChallenge {
  id: number;

  /** Timestamp of when the player found the place */
  foundTimestamp: Date;

  /** Members in the group during completion */
  completionPlayers: User[];

  /** Player owning this completion */
  owner: User;

  /** The completed challenge */
  challenge: Challenge;
}
