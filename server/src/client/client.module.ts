import { Module } from '@nestjs/common';
import { AuthModule } from 'src/auth/auth.module';
import { ClientGateway } from './client.gateway';
import { ClientService } from './client.service';

@Module({
  imports: [AuthModule],
  providers: [ClientGateway, ClientService],
  exports: [ClientGateway, ClientService],
})
export class ClientModule {}
