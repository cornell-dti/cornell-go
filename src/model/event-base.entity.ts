import { Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
export class EventBase {
  @PrimaryGeneratedColumn('uuid')
  id: string;
}
