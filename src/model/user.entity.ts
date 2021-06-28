import {
  Column,
  Entity,
  JoinTable,
  ManyToMany,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
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
 * Entity descibing a user in the database
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

  /** Score calculated upon completion of each challenge, could be more than length of prevChallenges */
  @Column()
  score: number;

  @Column()
  email: string;

  /** Challenges completed by the groups this players is/was part of */
  @ManyToMany(() => PrevChallenge)
  @JoinTable()
  prevChallenges: PrevChallenge[];
}
