import {
  Column,
  Entity,
  ManyToOne,
  OneToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Group } from './group.entity';
import { User } from './user.entity';

/**
 * Entity describing a user's membership in a group
 */
@Entity()
export class GroupMember {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  isHost!: boolean;

  /** Group this member is part of */
  @ManyToOne(() => Group, { cascade: ['update'] })
  group!: Group;

  /** User this membership describes */
  @OneToOne(() => User, { cascade: ['update'] })
  user!: User;
}
