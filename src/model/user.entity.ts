import {
  Column,
  Entity,
  JoinTable,
  ManyToMany,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { EventProgress } from './event-progress.entity';
import { PrevChallenge } from './prev-challenge.entity';

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

  /** Score calculated upon completion of each challenge */
  @Column()
  score: number;

  @Column()
  email: string;

  /** Event trackers for each event the player participated in */
  @OneToMany(() => EventProgress, (ev) => ev.player)
  participatingEvents: EventProgress[];
}
