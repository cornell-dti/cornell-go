import {
  Entity,
  IdentifiedReference,
  ManyToOne,
  PrimaryKey,
  Property,
} from '@mikro-orm/core';
import { v4 } from 'uuid';
import { EventBase } from './event-base.entity';
import { User } from './user.entity';

/**
 * Entity describing a unique reward to be given to a player
 */
@Entity()
export class EventReward {
  @PrimaryKey()
  id = v4();

  /** Event this rewards was assigned to */
  @ManyToOne()
  containingEvent!: IdentifiedReference<EventBase>;

  /** User who earned this reward */
  @ManyToOne({ onDelete: 'cascade' })
  claimingUser?: IdentifiedReference<User>;

  /** Short description of reward displayed to users e.g "50% off at XYZ store" */
  @Property()
  rewardDescription!: string;

  /** Information about how to redeem the reward */
  @Property()
  rewardRedeemInfo!: string;

  /** True if the reward is already redeemed */
  @Property()
  isRedeemed!: boolean;
}
