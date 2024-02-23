import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ClaimedResourceType, User, ClaimType } from '@prisma/client';

@Injectable()
export class ClaimService {
  constructor(private prisma: PrismaService) {}

  async modifyClaims(
    claimType: ClaimType,
    issuer: User | null,
    user: User | null,
    resourceType: ClaimedResourceType | null,
    resources: string[] | null,
    propertyNames: string[] | null,
  ): Promise<boolean> {
    return false;
  }

  async checkClaims(
    claimType: ClaimType,
    user: User | null,
    resourceType: ClaimedResourceType | null,
    resources: string[] | null,
    propertyNames: string[] | null,
  ): Promise<boolean> {
    return false;
  }

  async filterAllowedIds(
    claimType: ClaimType,
    user: User,
    resourceType: ClaimedResourceType,
    resources: string[],
    propertyNames: string[] | null,
  ): Promise<string[]> {
    return [];
  }

  async deleteDisabledProperties(
    claimType: ClaimType,
    user: User,
    resourceType: ClaimedResourceType,
    resources: any[],
    resourceIds: string[],
    propertyNames: string[] | null,
  ): Promise<void> {}
}
