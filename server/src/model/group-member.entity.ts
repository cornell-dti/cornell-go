import {
  Entity,
  IdentifiedReference,
  ManyToOne,
  OneToOne,
  PrimaryKey,
  Property,
} from '@mikro-orm/core';
import { Group } from './group.entity';
import { User } from './user.entity';

/**
 * Entity describing a user's membership in a group
 */
@Entity()
export class GroupMember {
  @PrimaryKey()
  id!: number;

  @Property()
  isHost!: boolean;

  /** Group this member is part of */
  @ManyToOne()
  group!: IdentifiedReference<Group>;

  /** User this membership describes */
  @OneToOne(() => User, user => user.groupMember)
  user!: IdentifiedReference<User>;
}
