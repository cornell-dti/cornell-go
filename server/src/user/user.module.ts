import { forwardRef, Module } from '@nestjs/common';
import { EventModule } from '../event/event.module';
import { GroupModule } from '../group/group.module';
import { UserService } from './user.service';
import { UserGateway } from './user.gateway';
import { ClientModule } from 'src/client/client.module';
import { AuthModule } from 'src/auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [
    forwardRef(() => EventModule),
    forwardRef(() => AuthModule),
    GroupModule,
    ClientModule,
    PrismaModule,
  ],
  providers: [UserService, UserGateway],
  exports: [UserService, UserGateway],
})
export class UserModule {}
