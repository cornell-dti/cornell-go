import { Module } from '@nestjs/common';
import { AuthModule } from 'src/auth/auth.module';
import { AdminGateway } from './admin.gateway';
import { AdminService } from './admin.service';
import { AdminCallbackService } from './admin-callback/admin-callback.service';
import { ClientModule } from 'src/client/client.module';
import { MikroOrmModule } from '@mikro-orm/nestjs';
import { User } from 'src/model/user.entity';
import { EventBase } from 'src/model/event-base.entity';
import { Challenge } from 'src/model/challenge.entity';
import { EventReward } from 'src/model/event-reward.entity';
import { UserModule } from 'src/user/user.module';
import { Group } from 'src/model/group.entity';

@Module({
  imports: [
    AuthModule,
    ClientModule,
    UserModule,
    MikroOrmModule.forFeature([User, Group, EventBase, Challenge, EventReward]),
  ],
  providers: [AdminGateway, AdminService, AdminCallbackService],
  controllers: [],
})
export class AdminModule {}
