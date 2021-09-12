import { Point } from 'geojson';
import {
  Column,
  Entity,
  Index,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { EventBase } from './event-base.entity';
import { PrevChallenge } from './prev-challenge.entity';

/**
 * Entity describing a challenge associated with a place
 */
@Entity()
export class Challenge {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** Index of the challenge relative to others in the linked event, -1 if last */
  @Index()
  @Column()
  eventIndex!: number;

  @Column()
  name!: string;

  @Column()
  description!: string;

  @Column()
  imageUrl!: string;

  @Index({ spatial: true })
  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
  })
  location!: Point;

  /** Event linked to this challenge */
  @ManyToOne(() => EventBase)
  linkedEvent!: EventBase;

  /** Radius within which the challenge is awarded */
  @Column()
  awardingRadius!: number;

  /** Radius within which the player is considered close, greater than `awardingRadius` */
  @Column()
  closeRadius!: number;

  /** Completions linked to this challenge */
  @OneToMany(() => PrevChallenge, pc => pc.challenge)
  completions!: PrevChallenge[];
}
