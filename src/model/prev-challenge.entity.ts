import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToMany,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Challenge } from './challenge.entity';
import { EventBase } from './event-base.entity';
import { User } from './user.entity';

@Entity()
export class PrevChallenge {
  @PrimaryGeneratedColumn()
  id: number;

  /** Timestamp of when the group found the place */
  @CreateDateColumn()
  foundTimestamp: Date;

  /** The completed challenge */
  @ManyToOne(() => Challenge)
  challenge: Challenge;

  /** The event that challenge was part of */
  @ManyToOne(() => EventBase)
  event: EventBase;

  /** The players that found this challenge */
  @ManyToMany(() => User)
  players: User[];
}
