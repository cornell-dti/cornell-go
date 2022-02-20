import { forwardRef, Module } from '@nestjs/common';
import { GroupMember } from '../model/group-member.entity';
import { Group } from '../model/group.entity';
import { GroupService } from './group.service';
import { GroupGateway } from './group.gateway';
import { UserModule } from '../user/user.module';
import { ClientModule } from 'src/client/client.module';
import { MikroOrmModule } from '@mikro-orm/nestjs';
import { AuthModule } from 'src/auth/auth.module';

@Module({
  imports: [
    MikroOrmModule.forFeature([Group, GroupMember]),
    forwardRef(() => UserModule),
    ClientModule,
    AuthModule,
  ],
  providers: [GroupService, GroupGateway],
  exports: [GroupService],
})
export class GroupModule {}
