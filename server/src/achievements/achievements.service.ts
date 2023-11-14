import { Injectable } from '@nestjs/common';
import { EventReward, PrismaClient, User } from '@prisma/client';
import { ClientService } from '../client/client.service';
import { PrismaService } from '../prisma/prisma.service';
import { AchievementDto, AchievementTrackerDto } from './achievements.dto';

@Injectable()
export class AchievementService {
  constructor(
    private prisma: PrismaService,
    private clientService: ClientService,
  ) {}
  
  async getAwardFromId(id: string) {
    return await this.prisma.achievement.findFirstOrThrow({ where: { id } });
  }
}
