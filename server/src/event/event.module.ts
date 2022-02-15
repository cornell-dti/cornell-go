import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EventBase } from '../model/event-base.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { EventReward } from '../model/event-reward.entity';
import { EventService } from './event.service';
import { EventGateway } from './event.gateway';
import { UserModule } from '../user/user.module';
import { ClientModule } from 'src/client/client.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([EventBase, EventTracker, EventReward]),
    UserModule,
    ClientModule,
  ],
  providers: [EventService, EventGateway],
  exports: [EventService],
})
export class EventModule {}
