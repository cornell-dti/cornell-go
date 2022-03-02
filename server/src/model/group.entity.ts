import {
  Collection,
  Entity,
  IdentifiedReference,
  ManyToOne,
  OneToMany,
  PrimaryKey,
  Property,
  Unique,
} from '@mikro-orm/core';
import { EventBase } from './event-base.entity';
import { GroupMember } from './group-member.entity';

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

  /** Members of the group, with the host at index 0 */
  @OneToMany(() => GroupMember, mem => mem.group)
  members = new Collection<GroupMember>(this);
}
