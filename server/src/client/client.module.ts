import { Module } from '@nestjs/common';
import { ClientGateway } from './client.gateway';
import { ClientService } from './client.service';

@Module({
  providers: [ClientGateway, ClientService],
  exports: [ClientService],
})
export class ClientModule {}
