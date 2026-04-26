import { Module } from '@nestjs/common';
import { ClientModule } from '../client/client.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { NotificationModule } from '../notification/notification.module';
import { CampusEventService } from './campus-event.service';
import { CampusEventGateway } from './campus-event.gateway';
import { RsvpReminderService } from './rsvp-reminder.service';

@Module({
  imports: [AuthModule, ClientModule, PrismaModule, NotificationModule],
  providers: [CampusEventService, CampusEventGateway, RsvpReminderService],
  exports: [CampusEventService, CampusEventGateway],
})
export class CampusEventModule {}
