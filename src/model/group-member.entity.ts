import { Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
export class GroupMember {
  @PrimaryGeneratedColumn()
  id: number;
}
