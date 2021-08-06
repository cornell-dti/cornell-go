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
import { EventReward } from './event-reward.entity';
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
  /** Cannot login through regular means */
  NONE = 'none',
}

/**
 * Entity describing a user in the database
 */
@Entity()
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** Token produced by an authentication service identifying this user */
  @Index()
  @Column({ unique: true })
  authToken!: string;

  /** The service used for authentication */
  @Index()
  @Column({
    type: 'enum',
    enum: AuthType,
    default: AuthType.NONE,
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

  @OneToMany(() => EventReward, ev => ev.claimingUser)
  rewards!: EventReward[];

  /** A user's membership in a group */
  @OneToOne(() => GroupMember, { nullable: true })
  @JoinColumn()
  groupMember!: GroupMember | null;

  /** Event trackers for each event the player participated in */
  @OneToMany(() => EventProgress, ev => ev.user)
  participatingEvents!: EventProgress[];

  /** Actions recorded relating to this user */
  @OneToMany(() => SessionLogEntry, entry => entry.user)
  logEntries!: SessionLogEntry[];
}
