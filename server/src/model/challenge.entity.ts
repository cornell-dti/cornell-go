import { Point } from 'geojson';
import {
  Column,
  Entity,
  Index,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { PrevChallenge } from './prev-challenge.entity';

/**
 * Entity describing a challenge associated with a place
 */
@Entity()
export class Challenge {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

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
