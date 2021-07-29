import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EventBase } from '../model/event-base.entity';
import { EventProgress } from '../model/event-progress.entity';
import { EventReward } from '../model/event-reward.entity';
import { EventService } from './event.service';
import { EventGateway } from './event.gateway';

@Module({
  imports: [TypeOrmModule.forFeature([EventBase, EventProgress, EventReward])],
  providers: [EventService, EventGateway],
  exports: [EventService],
})
export class EventModule {}
