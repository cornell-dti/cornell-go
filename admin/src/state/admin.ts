
@Entity()
export interface Admin {
  id: string;

  /** True if the user has rights over other admins */
  superuser: boolean;

  /** True if admin has approval to use admin tools */
  accessGranted: boolean;

  /** OAuth ID identifying the admin, currently only Google signin */
  oauthId: string;
}
