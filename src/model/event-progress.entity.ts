import {
  Column,
  Entity,
  ManyToMany,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { EventBase } from './event-base.entity';
import { PrevChallenge } from './prev-challenge.entity';
import { User } from './user.entity';

@Entity()
export class EventProgress {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => User)
  player: User;

  /** Event being tracked */
  @ManyToOne(() => EventBase)
  event: EventBase;

  /** Completed challenges */
  @ManyToMany(() => PrevChallenge)
  completed: PrevChallenge[];
}
