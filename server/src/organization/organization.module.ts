import { Module } from '@nestjs/common';
import { ClientModule } from 'src/client/client.module';
import { PrismaModule } from 'src/prisma/prisma.module';
import { OrganizationService } from './organization.service';

@Module({
  imports: [PrismaModule, ClientModule],
  exports: [OrganizationService],
  providers: [OrganizationService],
})
export class OrganizationModule {}
