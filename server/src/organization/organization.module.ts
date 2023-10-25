import { Module, forwardRef } from '@nestjs/common';
import { ClientModule } from '../client/client.module';
import { PrismaModule } from '../prisma/prisma.module';
import { OrganizationService } from './organization.service';
import { OrganizationGateway } from './organization.gateway';
import { AuthModule } from 'src/auth/auth.module';
import { UserModule } from '../user/user.module';

@Module({
  imports: [PrismaModule, ClientModule, forwardRef(() => AuthModule)],
  exports: [OrganizationService, OrganizationGateway],
  providers: [OrganizationService, OrganizationGateway],
})
export class OrganizationModule {}
