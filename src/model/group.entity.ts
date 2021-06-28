import { Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { EventBase } from './event-base.entity';

@Entity()
export class Group {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**  */
  @ManyToOne(() => EventBase)
  currentEvent: EventBase;
}
