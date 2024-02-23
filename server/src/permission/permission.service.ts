import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RestrictedResourceType, User, PermissionType } from '@prisma/client';
import { PermissionDto } from './permission.dto';

@Injectable()
export class PermissionService {
  constructor(private prisma: PrismaService) {}

  async createPermissionGroup(description: string) {}

  async grantPermissionGroup(
    authority: User | null,
    user: User,
    permGroupId: string,
  ): Promise<boolean> {
    return false;
  }

  async revokePermissionGroup(
    authority: User | null,
    user: User,
    permGroupId: string,
  ): Promise<boolean> {
    return false;
  }

  async aggregatePermissions(permGroupId: string): Promise<PermissionDto[]> {
    return [];
  }

  async getPermissionGroupMemberIds(permGroupId: string): Promise<string[]> {
    return [];
  }

  async modifyPermissionGroup(
    permGroupId: string,
    permissionType: PermissionType,
    authority: User | null,
    user: User | null,
    resourceType: RestrictedResourceType | null,
    resources: string[] | null,
    propertyNames: string[] | null,
  ): Promise<boolean> {
    return false;
  }

  async checkPermissions(
    user: User,
    accessType: PermissionType,
    resourceType: RestrictedResourceType | null,
    resources: string[] | null,
    propertyNames: string[] | null,
  ): Promise<boolean> {
    return false;
  }

  async filterAllowedResourceIds(
    user: User,
    accessType: PermissionType,
    resourceType: RestrictedResourceType,
    resources: string[],
    propertyNames: string[] | null,
  ): Promise<string[]> {
    return [];
  }

  async deleteForbiddenProperties(
    user: User,
    accessType: PermissionType,
    resourceType: RestrictedResourceType,
    resources: any[],
    resourceIds: string[],
  ): Promise<void> {}
}
