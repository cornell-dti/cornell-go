import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GroupMember } from '../model/group-member.entity';
import { Group } from '../model/group.entity';
import { GroupService } from './group.service';
import { GroupGateway } from './group.gateway';
import { UserModule } from '../user/user.module';

@Module({
  imports: [TypeOrmModule.forFeature([Group, GroupMember]), UserModule],
  providers: [GroupService, GroupGateway],
  exports: [GroupService],
})
export class GroupModule {}
