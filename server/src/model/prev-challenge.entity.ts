import {
  Collection,
  Entity,
  IdentifiedReference,
  ManyToMany,
  ManyToOne,
  OneToOne,
  PrimaryKey,
  Property,
} from '@mikro-orm/core';
import { Challenge } from './challenge.entity';
import { User } from './user.entity';

/**
 * Entity describing a completed challenge
 */
@Entity()
// UNCOMMENT ASAP @Unique(['owner', 'challenge'])
export class PrevChallenge {
  @PrimaryKey()
  id!: number;

  /** Timestamp of when the player found the place */
  @Property()
  foundTimestamp = new Date();

  /** Members in the group during completion */
  @ManyToMany()
  completionPlayers = new Collection<User>(this);

  /** Player owning this completion */
  @OneToOne()
  owner!: IdentifiedReference<User>;

  /** The completed challenge */
  @ManyToOne()
  challenge!: IdentifiedReference<Challenge>;
}
