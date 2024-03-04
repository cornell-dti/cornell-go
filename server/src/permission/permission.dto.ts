export type RestrictedResourceDto =
  | 'ORGANIZATION'
  | 'USER'
  | 'EVENT'
  | 'CHALLENGE'
  | 'GROUP'
  | 'ACHIEVEMENT';

export type PermissionTypeDto =
  | 'MANAGE'
  | 'READ_WRITE'
  | 'READ_ONLY'
  | 'DENY_ALL';

export interface PermissionDto {
  resourceType: RestrictedResourceDto;
  permissionType: PermissionTypeDto;
  resourceIds?: string[];
  propertyNames?: string[];
}
