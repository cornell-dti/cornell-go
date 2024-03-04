import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  RestrictedResourceType,
  User,
  PermissionType,
  PermissionGroupAuditLogType,
} from '@prisma/client';
import {
  PermissionDto,
  PermissionTypeDto,
  RestrictedResourceDto,
} from './permission.dto';
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

  async aggregatePermissions(
    accessor: User | null,
    permGroupId: string,
  ): Promise<PermissionDto[]> {
    if (
      await this.checkFullPermissionGroup(
        accessor,
        PermissionType.MANAGE,
        permGroupId,
      )
    ) {
      return [];
    }

    const allResources = await this.prisma.permission.findMany({
      where: { resourceId: null, propertyName: null },
      distinct: ['permissionType', 'resourceType'],
    });

    const someResources = await this.prisma.permission.findMany({
      where: { resourceId: { not: null }, propertyName: null },
      orderBy: { permissionType: 'desc', resourceType: 'desc' },
    });

    const partialResources = await this.prisma.permission.findMany({
      where: { propertyName: { not: null } },
      orderBy: {
        permissionType: 'desc',
        resourceType: 'desc',
        propertyName: 'desc',
      },
    });

    const finalArr: PermissionDto[] = [
      ...allResources.map(perm => ({
        resourceType: perm.resourceType as RestrictedResourceDto,
        permissionType: perm.permissionType as PermissionTypeDto,
      })),
      ...someResources.reduce((acc, perm) => {
        const prevDto = acc.at(-1);

        // aggregate all (permType, resType) into one using array
        // comes sorted from DB so no need for a hash map
        if (
          !prevDto ||
          prevDto.permissionType != perm.permissionType ||
          prevDto.resourceType != perm.resourceType
        ) {
          acc.push({
            resourceType: perm.resourceType as RestrictedResourceDto,
            permissionType: perm.permissionType as PermissionTypeDto,
            resourceIds: [perm.resourceId as string],
          });
        } else {
          prevDto.resourceIds!.push(perm.id);
        }

        return acc;
      }, [] as PermissionDto[]),
      ...partialResources.reduce((acc, perm) => {
        // TODO: complete this function
        
        const prevDto = acc.at(-1);

        if (
          !prevDto ||
          prevDto.permissionType != perm.permissionType ||
          prevDto.resourceType != perm.resourceType
        ) {
          acc.push({
            resourceType: perm.resourceType as RestrictedResourceDto,
            permissionType: perm.permissionType as PermissionTypeDto,
            resourceIds: [perm.resourceId as string],
          });
        } else {
          prevDto.resourceIds!.push(perm.id);
        }

        return acc;
      }, [] as PermissionDto[]),
    ];

    return finalArr;
  }

  async getPermissionGroupUsers(
    accessor: User | null,
    permGroupId: string,
  ): Promise<string[]> {
    if (
      await this.checkFullPermissionGroup(
        accessor,
        PermissionType.MANAGE,
        permGroupId,
      )
    ) {
      return [];
    }

    return [];
  }

  async modifyPermissions(
    permGroupId: string | null,
    authority: User | null,
    permissions: PermissionDto[], // this may need to be something else to decouple DTOs from business logic
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
