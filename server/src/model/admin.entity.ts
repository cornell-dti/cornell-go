import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
export class Admin {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** True if the user has rights over other admins */
  @Column()
  superuser!: boolean;

  /** True if admin has approval to use admin tools */
  @Column()
  accessGranted!: boolean;

  /** OAuth ID identifying the admin, currently only Google signin */
  @Index()
  @Column()
  oauthId!: string;
}
