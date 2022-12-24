import { Module } from '@nestjs/common';
import { PrismaModule } from 'src/prisma/prisma.module';
import { OrganizationService } from './organization.service';

@Module({
  imports: [PrismaModule],
  exports: [OrganizationService],
  providers: [OrganizationService],
})
export class OrganizationModule {}
