import {
  Column,
  CreateDateColumn,
  Entity,
  JoinTable,
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

  /** Timestamp of when the player found the place */
  @CreateDateColumn()
  foundTimestamp: Date;

  /** Members in the group during completion */
  @ManyToMany(() => User)
  @JoinTable()
  completionPlayers: User[];

  /** The completed challenge */
  @ManyToOne(() => Challenge)
  challenge: Challenge;
}
