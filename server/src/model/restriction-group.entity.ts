import {
  Collection,
  Entity,
  ManyToMany,
  OneToMany,
  PrimaryKey,
  Property,
} from '@mikro-orm/core';
import { v4 } from 'uuid';
import { EventBase } from './event-base.entity';
import { User } from './user.entity';

/** Entity representing a group of users with restrictions */
@Entity()
export class RestrictionGroup {
  @PrimaryKey()
  id = v4();

  /** Any name for this restriction group */
  @Property()
  displayName!: string; // Curie

  /** Lowercase alphanumeric name with underscores */
  @Property()
  name!: string; // curie

  /** True if the users here can update their username */
  @Property()
  canEditUsername!: boolean; 

  /** Users restricted by this group */
  @OneToMany(() => User, u => u.restrictedBy)
  restrictedUsers = new Collection<User>(this);

  /** Events that are allowed for this user */
  @ManyToMany()
  allowedEvents = new Collection<EventBase>(this);

  /** Users with id-login that are made specifically for this restriction */
  @OneToMany(() => User, u => u.generatedBy)
  generatedUsers = new Collection<User>(this);
}
