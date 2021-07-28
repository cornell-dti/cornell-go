import {
  Column,
  Entity,
  Index,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { EventBase } from './event-base.entity';
import { GroupMember } from './group-member.entity';

@Entity()
export class Group {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** Current event of the group */
  @ManyToOne(() => EventBase)
  currentEvent!: EventBase;

  /** Friendly id of the group */
  @Column({ unique: true })
  @Index()
  friendlyId!: string;

  /** Members of the group, with the host at index 0 */
  @OneToMany(() => GroupMember, mem => mem.group)
  members!: GroupMember[];
}
