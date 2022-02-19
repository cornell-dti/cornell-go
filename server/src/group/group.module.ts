import { forwardRef, Module } from '@nestjs/common';
import { GroupMember } from '../model/group-member.entity';
import { Group } from '../model/group.entity';
import { GroupService } from './group.service';
import { GroupGateway } from './group.gateway';
import { UserModule } from '../user/user.module';
import { ClientModule } from 'src/client/client.module';
import { MikroOrmModule } from '@mikro-orm/nestjs';

@Module({
  imports: [
    MikroOrmModule.forFeature([Group, GroupMember]),
    forwardRef(() => UserModule),
    ClientModule,
  ],
  providers: [GroupService, GroupGateway],
  exports: [GroupService],
})
export class GroupModule {}
