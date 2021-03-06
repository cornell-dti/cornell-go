import {
  Collection,
  Entity,
  IdentifiedReference,
  Index,
  ManyToOne,
  OneToMany,
  PrimaryKey,
  Property,
} from '@mikro-orm/core';
import { Point } from 'geojson';

import { EventBase } from './event-base.entity';
import { PrevChallenge } from './prev-challenge.entity';

import { v4 } from 'uuid';

/**
 * Entity describing a challenge associated with a place
 */
@Entity()
export class Challenge {
  @PrimaryKey()
  id = v4();

  /** Index of the challenge relative to others in the linked event, 9999 if last */
  @Index()
  @Property()
  eventIndex!: number;

  @Property({ length: 2048 })
  name!: string;

  @Property({ length: 2048 })
  description!: string;

  @Property({ length: 2048 })
  imageUrl!: string;

  @Property({ columnType: 'double precision' })
  latitude!: number;

  @Property({ columnType: 'double precision' })
  longitude!: number;

  /** Event linked to this challenge */
  @ManyToOne()
  linkedEvent!: IdentifiedReference<EventBase>;

  /** Radius within which the challenge is awarded */
  @Property({ columnType: 'double precision' })
  awardingRadius!: number;

  /** Radius within which the player is considered close, greater than `awardingRadius` */
  @Property({ columnType: 'double precision' })
  closeRadius!: number;

  /** Completions linked to this challenge */
  @OneToMany(() => PrevChallenge, pc => pc.challenge, {
    orphanRemoval: true,
  })
  completions = new Collection<PrevChallenge>(this);
}
