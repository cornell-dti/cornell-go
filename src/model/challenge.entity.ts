import { Entity, PrimaryGeneratedColumn } from 'typeorm';

/**
 * Entity describing a challenge associated with a place
 */
@Entity()
export class Challenge {
  @PrimaryGeneratedColumn('uuid')
  id: string;
}
