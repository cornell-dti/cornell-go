import { Challenge } from './challenge';

import { EventBase } from './event-base';
import { PrevChallenge } from './prev-challenge';
import { User } from './user';

/**
 * Entity describing a player's progress on an event
 */
export interface EventTracker {
  id: number;

  /** Score calculated for this event alone */
  eventScore: number;

  /** True if a player is ranked, false if they have been disabled for this event  */
  isPlayerRanked: boolean;

  /** Timestamp after which a user can earn points for a challenge (allows for anticheat measures preventing car travel or spamming REST apis) */
  cooldownMinimum: Date;

  user: User;

  /** Event being tracked */
  event: EventBase;

  /** Currently selected challenge */
  currentChallenge: Challenge;

  /** Completed challenges */
  completed: PrevChallenge[];
}
