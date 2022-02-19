import { forwardRef, Module } from '@nestjs/common';
import { EventBase } from '../model/event-base.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { EventReward } from '../model/event-reward.entity';
import { EventService } from './event.service';
import { EventGateway } from './event.gateway';
import { UserModule } from '../user/user.module';
import { ClientModule } from 'src/client/client.module';
import { Challenge } from 'src/model/challenge.entity';
import { MikroOrmModule } from '@mikro-orm/nestjs';

@Module({
  imports: [
    MikroOrmModule.forFeature([
      EventBase,
      EventTracker,
      EventReward,
      Challenge,
    ]),
    forwardRef(() => UserModule),
    UserModule,
    ClientModule,
  ],
  providers: [EventService, EventGateway],
  exports: [EventService],
})
export class EventModule {}
