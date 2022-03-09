export interface UpdateAdminDataAdminDto {
  id: string;
  email: string;
  requesting: boolean;
  superuser: boolean;
}

export interface UpdateAdminDataDto {
  admins: UpdateAdminDataAdminDto[];
}
