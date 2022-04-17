import { forwardRef, Module } from '@nestjs/common';
import { EventModule } from '../event/event.module';
import { GroupModule } from '../group/group.module';
import { User } from '../model/user.entity';
import { UserService } from './user.service';
import { UserGateway } from './user.gateway';
import { ClientModule } from 'src/client/client.module';
import { AuthModule } from 'src/auth/auth.module';
import { MikroOrmModule } from '@mikro-orm/nestjs';
import { SessionLogEntry } from 'src/model/session-log-entry.entity';

@Module({
  imports: [
    MikroOrmModule.forFeature([User, SessionLogEntry]),
    forwardRef(() => EventModule),
    forwardRef(() => AuthModule),
    GroupModule,
    ClientModule,
  ],
  providers: [UserService, UserGateway],
  exports: [UserService, UserGateway],
})
export class UserModule {}
