import { Module } from '@nestjs/common';
import { PermissionService } from './permission.service';
import { PrismaModule } from '../prisma/prisma.module';
import { PermissionGateway } from './permission.gateway';

@Module({
  providers: [PermissionService, PermissionGateway],
  imports: [PrismaModule],
})
export class PermissionModule {}
