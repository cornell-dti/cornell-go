import { Module, forwardRef } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ClientGateway } from './client.gateway';
import { ClientService } from './client.service';
import { CaslModule } from '../casl/casl.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, CaslModule],
  providers: [ClientGateway, ClientService],
  exports: [ClientGateway, ClientService],
})
export class ClientModule {}
