import { Module, forwardRef } from '@nestjs/common';
import { ClientModule } from '../client/client.module';
import { PrismaModule } from '../prisma/prisma.module';
import { OrganizationService } from './organization.service';
import { OrganizationGateway } from './organization.gateway';
import { AuthModule } from '../auth/auth.module';
import { CaslModule } from '../casl/casl.module';

@Module({
  imports: [
    PrismaModule,
    ClientModule,
    forwardRef(() => AuthModule),
    forwardRef(() => CaslModule),
  ],
  exports: [OrganizationService, OrganizationGateway],
  providers: [OrganizationService, OrganizationGateway],
})
export class OrganizationModule {}
