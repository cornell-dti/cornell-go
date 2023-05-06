import { Module, forwardRef } from '@nestjs/common';
import { ClientModule } from 'src/client/client.module';
import { PrismaModule } from 'src/prisma/prisma.module';
import { OrganizationService } from './organization.service';
import { OrganizationGateway } from './organization.gateway';
import { AuthModule } from 'src/auth/auth.module';

@Module({
  imports: [PrismaModule, ClientModule, forwardRef(() => AuthModule)],
  exports: [OrganizationService],
  providers: [OrganizationService, OrganizationGateway],
})
export class OrganizationModule {}
