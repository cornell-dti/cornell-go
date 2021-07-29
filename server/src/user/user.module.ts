import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EventModule } from '../event/event.module';
import { GroupModule } from '../group/group.module';
import { User } from '../model/user.entity';
import { UserService } from './user.service';
import { UserGateway } from './user.gateway';

@Module({
  imports: [TypeOrmModule.forFeature([User]), EventModule, GroupModule],
  providers: [UserService, UserGateway],
  exports: [UserService],
})
export class UserModule {}
