import { Injectable } from '@nestjs/common';
import { PrismaClient, User, SessionLogEvent } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SessionLogService {
  constructor(private prisma: PrismaService) {}
  async logEvent(
    eventType: SessionLogEvent,
    data: string,
    userId: string | null,
  ) {
    return; // Prevent filling up the database for now

    await this.prisma.sessionLogEntry.create({
      data: {
        eventType,
        data,
        userId,
      },
    });
  }
}
