import {
  Column,
  Entity,
  Index,
  JoinColumn,
  OneToMany,
  OneToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { EventProgress } from './event-progress.entity';
import { GroupMember } from './group-member.entity';
import { SessionLogEntry } from './session-log-entry.entity';

/**
 * Enum describing the type of authentication token
 */
export enum AuthType {
  /** Uses Sign in with Google token */
  GOOGLE = 'google',
  /** Uses Sign in with Apple ID token */
  APPLE = 'apple',
  /** Uses ID from device to authenticate */
  DEVICE = 'device',
}

/**
 * Entity describing a user in the database
 */
@Entity()
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** Token produced by an authentication service identifying this user */
  @Column()
  authToken!: string;

  /** The Auth service used for authentication  */
  @Column({
    type: 'enum',
    enum: AuthType,
  })
  authType!: AuthType;

  @Column()
  username!: string;

  @Column()
  email!: string;

  /** Score calculated upon completion of each challenge added up */
  @Index()
  @Column()
  score!: number;

  /** A user's membership in a group */
  @OneToOne(() => GroupMember)
  @JoinColumn()
  groupMember!: GroupMember;

  /** Event trackers for each event the player participated in */
  @OneToMany(() => EventProgress, (ev) => ev.player)
  participatingEvents!: EventProgress[];

  /** Actions recorded relating to this user */
  @OneToMany(() => SessionLogEntry, (entry) => entry.user)
  logEntries!: SessionLogEntry[];
}
