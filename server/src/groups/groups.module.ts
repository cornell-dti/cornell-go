import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GroupMember } from '../model/group-member.entity';
import { Group } from '../model/group.entity';
import { GroupsService } from './groups.service';

@Module({
  imports: [TypeOrmModule.forFeature([Group, GroupMember])],
  providers: [GroupsService],
  exports: [GroupsService],
})
export class GroupsModule {}
