import { Module } from '@nestjs/common';
import { ClientModule } from 'src/client/client.module';
import { EventModule } from '../event/event.module';
import { GroupModule } from '../group/group.module';
import { PrismaModule } from '../prisma/prisma.module';
import { UserGateway } from './user.gateway';
import { UserService } from './user.service';

@Module({
  imports: [ClientModule, GroupModule, PrismaModule, EventModule],
  providers: [UserService, UserGateway],
  exports: [UserService, UserGateway],
})
export class UserModule {}
