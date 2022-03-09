export interface UpdateAdminDataAdminDto {
  email: string;
  approved: boolean;
  superuser: boolean;
}

export interface UpdateAdminDataDto {
  admins: UpdateAdminDataAdminDto[];
}
