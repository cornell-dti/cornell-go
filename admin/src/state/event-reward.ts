import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { EventBase } from './event-base';
import { User } from './user';

/**
 * Entity describing a unique reward to be given to a player
 */
@Entity()
export interface EventReward {
  id: string;

  /** Event this rewards was assigned to */
  containingEvent: EventBase;

  /** User who earned this reward */
  claimingUser: User | null;

  /** Short description of reward displayed to users e.g "50% off at XYZ store" */
  rewardDescription: string;

  /** Information about how to redeem the reward */
  rewardRedeemInfo: string;

  /** True if the reward is already redeemed */
  isRedeemed: boolean;
}
