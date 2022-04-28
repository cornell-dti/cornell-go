import {
  Collection,
  Entity,
  IdentifiedReference,
  ManyToOne,
  OneToMany,
  OneToOne,
  PrimaryKey,
  Property,
  Unique,
} from '@mikro-orm/core';
import { EventBase } from './event-base.entity';
import { User } from './user.entity';

@Entity()
export class Group {
  @PrimaryKey()
  id!: string;

  /** Current event of the group */
  @ManyToOne()
  currentEvent!: IdentifiedReference<EventBase>;

  /** Friendly id of the group */
  @Property()
  @Unique()
  friendlyId!: string;

  /** The host of the group */
  @OneToOne({ nullable: true })
  host!: IdentifiedReference<User>;

  /** Members of the group */
  @OneToMany(() => User, mem => mem.group)
  members = new Collection<User>(this);
}
