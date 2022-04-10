import { forwardRef, Module } from '@nestjs/common';
import { Group } from '../model/group.entity';
import { GroupService } from './group.service';
import { GroupGateway } from './group.gateway';
import { UserModule } from '../user/user.module';
import { ClientModule } from 'src/client/client.module';
import { EventModule } from '../event/event.module';
import { MikroOrmModule } from '@mikro-orm/nestjs';
import { AuthModule } from 'src/auth/auth.module';

@Module({
  imports: [
    MikroOrmModule.forFeature([Group]),
    forwardRef(() => UserModule),
    ClientModule,
    AuthModule,
    forwardRef(() => EventModule),
  ],
  providers: [GroupService, GroupGateway],
  exports: [GroupService, GroupGateway],
})
export class GroupModule {}
