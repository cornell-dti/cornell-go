import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';

const REMINDER_LEAD_TIME_MS = 3 * 60 * 60 * 1000; // 3 hours before event
const CRON_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes (matches cron frequency)

@Injectable()
export class RsvpReminderService {
  private readonly logger = new Logger(RsvpReminderService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationService: NotificationService,
  ) {}

  @Cron(CronExpression.EVERY_5_MINUTES)
  async handleReminderCron() {
    const now = Date.now();
    const windowStart = new Date(now + REMINDER_LEAD_TIME_MS);
    const windowEnd = new Date(now + REMINDER_LEAD_TIME_MS + CRON_INTERVAL_MS);

    const rsvps = await this.prisma.eventRSVP.findMany({
      where: {
        reminderSent: false,
        campusEvent: {
          startTime: {
            gte: windowStart,
            lt: windowEnd,
          },
        },
      },
      include: {
        campusEvent: { select: { title: true, startTime: true } },
      },
    });

    if (rsvps.length === 0) return;

    this.logger.log(`Sending reminders for ${rsvps.length} RSVPs`);

    for (const rsvp of rsvps) {
      const { title, startTime } = rsvp.campusEvent;
      const timeStr = startTime.toLocaleTimeString([], {
        hour: '2-digit',
        minute: '2-digit',
      });

      await this.notificationService.sendToUser(
        rsvp.userId,
        `Upcoming Event: ${title}`,
        `Starts at ${timeStr} — see you there!`,
        { campusEventId: rsvp.campusEventId },
      );

      await this.prisma.eventRSVP.update({
        where: { id: rsvp.id },
        data: { reminderSent: true },
      });
    }

    this.logger.log(`Finished sending ${rsvps.length} reminders`);
  }
}
