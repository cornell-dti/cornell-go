import {
  Column,
  Entity,
  Index,
  ManyToMany,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { EventBase } from './event-base.entity';
import { PrevChallenge } from './prev-challenge.entity';
import { User } from './user.entity';

/**
 * Entity describing a player's progress on an event
 */
@Entity()
export class EventProgress {
  @PrimaryGeneratedColumn()
  id!: number;

  /** Score calculated for this event alone */
  @Index()
  @Column()
  eventScore!: number;

  /** True if a player is ranked, false if they have beem disabled for this event  */
  @Column()
  isPlayerRanked!: boolean;

  /** Timestamp after which a user can earn points for a challenge (allows for anticheat measures preventing car travel or spamming REST apis) */
  @Column({ type: 'timestamp with time zone' })
  cooldownMinimum!: Date;

  @ManyToOne(() => User)
  player!: User;

  /** Event being tracked */
  @ManyToOne(() => EventBase)
  event!: EventBase;

  /** Completed challenges */
  @ManyToMany(() => PrevChallenge)
  completed!: PrevChallenge[];
}
