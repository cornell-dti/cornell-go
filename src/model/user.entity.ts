import {
  Column,
  Entity,
  JoinColumn,
  OneToMany,
  OneToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { EventProgress } from './event-progress.entity';
import { GroupMember } from './group-member.entity';
import { SessionLogEntry } from './session-log-entry.entity';

/**
 * Enum describing the type of OAuth token
 */
export enum OAuthType {
  /** Uses Sign in with Google token */
  GOOGLE = 'google',
  /** Uses Sign in with Apple ID token */
  APPLE = 'apple',
}

/**
 * Enum describing a user account's role
 */
export enum UserRole {
  /** Has no special privileges */
  PLAYER = 'player',
  /** Has privileges to modify player, group, event, and challenge data directly */
  ADMIN = 'admin',
}

/**
 * Entity describing a user in the database
 */
@Entity()
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** Token produced by an OAuth 2 service identifying this user */
  @Column()
  oauthToken: string;

  /** The OAuth 2 service used for authentication  */
  @Column({
    type: 'enum',
    enum: OAuthType,
  })
  oauthType: OAuthType;

  @Column()
  username: string;

  @Column()
  email: string;

  /** Score calculated upon completion of each challenge added up */
  @Column()
  score: number;

  /** A user's membership in a group */
  @OneToOne(() => GroupMember)
  @JoinColumn()
  groupMember: GroupMember;

  /** Event trackers for each event the player participated in */
  @OneToMany(() => EventProgress, (ev) => ev.player)
  participatingEvents: EventProgress[];

  /** Actions recorded relating to this user */
  @OneToMany(() => SessionLogEntry, (entry) => entry.user)
  logEntries: SessionLogEntry[];
}
