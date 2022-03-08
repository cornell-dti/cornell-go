export interface UpdateAdminsAdminUpdateDto {
  email: string;
  status: 'approve' | 'deny';
}

export interface UpdateAdminsDto {
  adminUpdates: UpdateAdminsAdminUpdateDto[];
}
