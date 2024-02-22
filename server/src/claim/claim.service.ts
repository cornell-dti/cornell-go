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
  ) {}
}
