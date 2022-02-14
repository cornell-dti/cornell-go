import { forwardRef, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EventModule } from '../event/event.module';
import { GroupModule } from '../group/group.module';
import { User } from '../model/user.entity';
import { UserService } from './user.service';
import { UserGateway } from './user.gateway';
import { ClientModule } from 'src/client/client.module';
import { AuthModule } from 'src/auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([User]),
    forwardRef(() => EventModule),
    forwardRef(() => AuthModule),
    GroupModule,
    ClientModule,
  ],
  providers: [UserService, UserGateway],
  exports: [UserService],
})
export class UserModule {}
