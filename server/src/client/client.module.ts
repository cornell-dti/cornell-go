import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ClientGateway } from './client.gateway';
import { ClientService } from './client.service';

@Module({
  imports: [PrismaModule],
  providers: [ClientGateway, ClientService],
  exports: [ClientGateway, ClientService],
})
export class ClientModule {}
