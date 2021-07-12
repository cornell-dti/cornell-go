import { Point } from 'geojson';
import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

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

  /** Radius within the player is considered close, greater than `awardingRadius` */
  @Column()
  closeRadius!: number;
}
