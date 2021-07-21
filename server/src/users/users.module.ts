import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EventsModule } from '../events/events.module';
import { GroupsModule } from '../groups/groups.module';
import { User } from '../model/user.entity';
import { UsersService } from './users.service';

@Module({
  imports: [TypeOrmModule.forFeature([User]), EventsModule, GroupsModule],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
