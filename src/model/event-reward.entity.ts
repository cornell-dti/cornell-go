import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { EventBase } from './event-base.entity';
import { User } from './user.entity';

/**
 * Entity describing a unique reward to be given to a player
 */
@Entity()
export class EventReward {
  @PrimaryGeneratedColumn()
  id: number;

  /** Event this rewards was assigned to */
  @ManyToOne(() => EventBase)
  containingEvent: EventBase;

  /** User who earned this reward */
  @ManyToOne(() => User)
  claimingUser: User;

  /** Short description of reward displayed to users e.g "50% off at XYZ store" */
  @Column()
  rewardDescription: string;

  /** Information about how to redeem the reward */
  @Column()
  rewardRedeemInfo: string;

  /** True if the information is a link */
  @Column()
  isInfoLink: boolean;
}
