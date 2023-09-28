import { Module } from '@nestjs/common';
import { ClientModule } from '../client/client.module';
import { PrismaModule } from '../prisma/prisma.module';
import { OrganizationService } from './organization.service';

@Module({
  imports: [PrismaModule, ClientModule],
  exports: [OrganizationService],
  providers: [OrganizationService],
})
export class OrganizationModule {}
