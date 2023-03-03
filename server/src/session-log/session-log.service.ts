import { Injectable } from '@nestjs/common';
import { PrismaClient, User, SessionLogEvent } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class SessionLogService {
  constructor(private prisma: PrismaService) {}
  async logEvent(
    eventType: SessionLogEvent,
    data: string,
    userId: string | null,
  ) {
    await this.prisma.sessionLogEntry.create({
      data: {
        eventType,
        data,
        userId,
      },
    });
  }
}