import { EventTracker } from './event-tracker.entity';
import { EventReward } from './event-reward.entity';
import { SessionLogEntry } from './session-log-entry.entity';
import {
  Cascade,
  Collection,
  Entity,
  Enum,
  IdentifiedReference,
  Index,
  ManyToMany,
  ManyToOne,
  OneToMany,
  OneToOne,
  PrimaryKey,
  Property,
  Unique,
} from '@mikro-orm/core';
import { v4 } from 'uuid';
import { Group } from './group.entity';
import { RestrictionGroup } from './restriction-group.entity';
import { PrevChallenge } from './prev-challenge.entity';

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
  @PrimaryKey()
  id = v4();

  /** Token produced by an authentication service identifying this user */
  @Unique()
  @Property({ length: 2048 })
  authToken!: string;

  /** The service used for authentication */
  @Index()
  @Enum(() => AuthType)
  authType!: AuthType;

  @Property({ length: 2048 })
  username!: string;

  @Property({ length: 2048 })
  email!: string;

  @Property({ length: 2048 })
  hashedRefreshToken!: string;

  /** True if the user has rights over other admins */
  @Property()
  superuser!: boolean;

  /** True if admin has approval to use admin tools */
  @Property()
  adminGranted!: boolean;

  @Property()
  adminRequested!: boolean;

  /** Score calculated upon completion of each challenge added up */
  @Index()
  @Property()
  score!: number;

  @OneToMany(() => EventReward, ev => ev.claimingUser)
  rewards = new Collection<EventReward>(this);

  /** A user's membership in a group */
  @ManyToOne({ inversedBy: 'members', nullable: true })
  group!: IdentifiedReference<Group>;

  /** Event trackers for each event the player participated in */
  @OneToMany(() => EventTracker, ev => ev.user, {
    orphanRemoval: true,
  })
  participatingEvents = new Collection<EventTracker>(this);

  /** Actions recorded relating to this user */
  @OneToMany(() => SessionLogEntry, entry => entry.user, {
    orphanRemoval: true,
  })
  logEntries = new Collection<SessionLogEntry>(this);

  /** Prev challenges */
  @OneToMany(() => PrevChallenge, pc => pc.owner, {
    orphanRemoval: true,
  })
  prevChallenges = new Collection<PrevChallenge>(this);

  /** The restriction group this user is made for */
  @ManyToOne()
  generatedBy?: IdentifiedReference<RestrictionGroup>;

  /** The restriction group this user is in */
  @ManyToOne()
  restrictedBy?: IdentifiedReference<RestrictionGroup>;

  /** Is player ranked on the leaderboards */
  @Property()
  isRanked = true;
}
