export interface UpdateAdminsAdminUpdateDto {
  id: string;
  granted: boolean;
}

export interface UpdateAdminsDto {
  adminUpdates: UpdateAdminsAdminUpdateDto[];
}
