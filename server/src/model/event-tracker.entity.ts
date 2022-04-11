import {
  Collection,
  Entity,
  IdentifiedReference,
  Index,
  ManyToMany,
  ManyToOne,
  PrimaryKey,
  Property,
} from '@mikro-orm/core';
import { v4 } from 'uuid';
import { Challenge } from './challenge.entity';

import { EventBase } from './event-base.entity';
import { PrevChallenge } from './prev-challenge.entity';
import { User } from './user.entity';

/**
 * Entity describing a player's progress on an event
 */
@Entity()
export class EventTracker {
  @PrimaryKey()
  id = v4();

  /** Score calculated for this event alone */
  @Index()
  @Property()
  eventScore!: number;

  /** True if a player is ranked, false if they have been disabled for this event  */
  @Property()
  isPlayerRanked!: boolean;

  /** Timestamp after which a user can earn points for a challenge (allows for anticheat measures preventing car travel or spamming REST apis) */
  @Property()
  cooldownMinimum!: Date;

  @ManyToOne()
  user!: IdentifiedReference<User>;

  /** Event being tracked */
  @ManyToOne()
  event!: IdentifiedReference<EventBase>;

  /** Currently selected challenge */
  @ManyToOne()
  currentChallenge!: IdentifiedReference<Challenge>;

  /** Completed challenges */
  @ManyToMany(() => PrevChallenge)
  completed = new Collection<PrevChallenge>(this);
}
