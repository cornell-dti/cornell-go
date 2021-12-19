
import { EventBase } from './event-base';
import { PrevChallenge } from './prev-challenge';

/**
 * Entity describing a challenge associated with a place
 */
export interface Challenge {
  id: string;

  /** Index of the challenge relative to others in the linked event, -1 if last */
  eventIndex: number;
  name: string;

  description: string;

  imageUrl: string;

  location: Point;

  /** Event linked to this challenge */
  linkedEvent: EventBase;

  /** Radius within which the challenge is awarded */
  awardingRadius: number;

  /** Radius within which the player is considered close, greater than `awardingRadius` */
  closeRadius: number;

  /** Completions linked to this challenge */
  completions: PrevChallenge[];
}
