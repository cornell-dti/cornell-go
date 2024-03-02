import { Module } from '@nestjs/common';
import { PermissionService } from './permission.service';
import { PrismaModule } from '../prisma/prisma.module';
import { PermissionGateway } from './permission.gateway';
import { AuthModule } from '../auth/auth.module';
import { ClientModule } from '../client/client.module';

@Module({
  providers: [PermissionService, PermissionGateway],
  imports: [PrismaModule, ClientModule],
})
export class PermissionModule {}
