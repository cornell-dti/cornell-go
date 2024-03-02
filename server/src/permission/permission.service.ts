import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  RestrictedResourceType,
  User,
  PermissionType,
  PermissionGroupAuditLogType,
} from '@prisma/client';
import { PermissionDto } from './permission.dto';
import { AuthService } from '../auth/auth.service';
import { ClientService } from '../client/client.service';

export interface PermissionDeniedInfo {
  message: string;
}

export type PermissionCheckResult = null | PermissionDeniedInfo;

@Injectable()
export class PermissionService {
  constructor(
    private prisma: PrismaService,
    private authService: AuthService,
    private clientService: ClientService,
  ) {}

  async createPermissionGroup(
    creator: User | null,
    description: string,
  ): Promise<string> {
    return (
      await this.prisma.permissionGroup.create({
        select: { id: true },
        data: {
          description,
          auditLog: {
            create: {
              auditType: PermissionGroupAuditLogType.CREATED,
              actorId: creator?.id,
            },
          },
        },
      })
    ).id;
  }

  async grantPermissionGroup(
    authority: User | null,
    user: User,
    permGroupId: string,
  ): Promise<PermissionCheckResult> {
    const result = await this.checkFullPermissionGroup(
      authority,
      PermissionType.MANAGE,
      permGroupId,
    );

    if (result) return result;

    await this.prisma.permissionGroup.update({
      where: { id: permGroupId },
      data: {
        members: {
          connect: {
            id: user.id,
          },
        },
        auditLog: {
          create: {
            auditType: PermissionGroupAuditLogType.GRANTED_TO,
            actorId: authority?.id,
            relatedId: user.id,
          },
        },
      },
    });

    return null;
  }

  async revokePermissionGroup(
    authority: User | null,
    user: User,
    permGroupId: string,
  ): Promise<PermissionCheckResult> {
    const result = await this.checkFullPermissionGroup(
      authority,
      PermissionType.MANAGE,
      permGroupId,
    );

    if (result) return result;

    await this.prisma.permissionGroup.update({
      where: { id: permGroupId },
      data: {
        members: {
          disconnect: {
            id: user.id,
          },
        },
        auditLog: {
          create: {
            auditType: PermissionGroupAuditLogType.REVOKED_FROM,
            actorId: authority?.id,
            relatedId: user.id,
          },
        },
      },
    });

    return null;
  }

  async aggregatePermissions(permGroupId: string): Promise<PermissionDto[]> {
    return [];
  }

  async getPermissionGroupUsers(permGroupId: string): Promise<string[]> {
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
  ): Promise<PermissionCheckResult> {
    return { message: 'not implemented' };
  }

  async checkFullPermissionGroup(
    user: User | null,
    permissionType: PermissionType,
    permGroupId: string,
  ): Promise<PermissionCheckResult> {
    return { message: 'not implemented' };
  }

  async checkPermissions(
    user: User | null,
    accessType: PermissionType,
    resourceType: RestrictedResourceType | null,
    resources: string[] | null,
    propertyNames: string[] | null,
  ): Promise<PermissionCheckResult> {
    return { message: 'not implemented' };
  }

  async filterAllowedResourceIds(
    user: User | null,
    accessType: PermissionType,
    resourceType: RestrictedResourceType,
    resources: string[],
    propertyNames: string[] | null,
  ): Promise<string[]> {
    return [];
  }

  async deleteForbiddenProperties(
    user: User | null,
    accessType: PermissionType,
    resourceType: RestrictedResourceType,
    resources: any[],
    resourceIds: string[],
  ): Promise<void> {}

  async sendUpdateProtected(
    eventName: string,
    resourceId: string,
    resourceType: RestrictedResourceType,
    dto: any,
    receiver: User | undefined,
  ) {}
}
