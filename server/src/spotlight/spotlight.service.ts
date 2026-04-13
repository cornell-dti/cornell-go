import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';
import { calculateDistanceInMeters } from '../utils/geo.util';
import {
  SpotlightDto,
  ActiveSpotlightDto,
  SpotlightNotificationResultDto,
} from './spotlight.dto';

const DAILY_CAP = 1;
const CAMPUS_TIMEZONE = 'America/New_York';

@Injectable()
export class SpotlightService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationService: NotificationService,
  ) {}

  async getActiveSpotlights(): Promise<ActiveSpotlightDto[]> {
    const now = new Date();
    const spotlights = await this.prisma.locationSpotlight.findMany({
      where: {
        isActive: true,
        startDate: { lte: now },
        endDate: { gte: now },
      },
      select: {
        id: true,
        latitude: true,
        longitude: true,
        radiusMeters: true,
      },
    });
    return spotlights;
  }

  async requestNotification(
    userId: string,
    spotlightId: string,
    userLat: number,
    userLng: number,
  ): Promise<SpotlightNotificationResultDto> {
    const spotlight = await this.prisma.locationSpotlight.findUnique({
      where: { id: spotlightId },
    });

    if (!spotlight || !spotlight.isActive) {
      return { sent: false, reason: 'Spotlight not found or inactive' };
    }

    const now = new Date();

    // Check active date range
    if (now < spotlight.startDate || now > spotlight.endDate) {
      return { sent: false, reason: 'Spotlight not in active date range' };
    }

    // Check time window (campus timezone)
    const campusHour = this.getCampusHour(now);
    if (campusHour < spotlight.startHour || campusHour >= spotlight.endHour) {
      return { sent: false, reason: 'Outside notification hours' };
    }

    // Verify proximity server-side
    const distance = calculateDistanceInMeters(
      userLat,
      userLng,
      spotlight.latitude,
      spotlight.longitude,
    );
    if (distance > spotlight.radiusMeters) {
      return { sent: false, reason: 'Not within spotlight radius' };
    }

    // Check daily cap
    const startOfDay = this.getStartOfCampusDay(now);
    const todayCount = await this.prisma.spotlightNotificationLog.count({
      where: {
        userId,
        notifiedAt: { gte: startOfDay },
      },
    });
    if (todayCount >= DAILY_CAP) {
      return { sent: false, reason: 'Daily notification limit reached' };
    }

    // Check per-spotlight cooldown
    const cooldownCutoff = new Date(now);
    cooldownCutoff.setDate(cooldownCutoff.getDate() - spotlight.cooldownDays);
    const recentLog = await this.prisma.spotlightNotificationLog.findFirst({
      where: {
        userId,
        spotlightId,
        notifiedAt: { gte: cooldownCutoff },
      },
    });
    if (recentLog) {
      return { sent: false, reason: 'Cooldown period active' };
    }

    // Check completion filter
    if (spotlight.linkedEventId) {
      const completed = await this.prisma.prevChallenge.findFirst({
        where: {
          userId,
          challenge: { linkedEventId: spotlight.linkedEventId },
        },
      });
      if (completed) {
        return { sent: false, reason: 'Linked event already completed' };
      }
    }
    if (spotlight.linkedCampusEventId) {
      const attended = await this.prisma.eventAttendance.findFirst({
        where: {
          userId,
          campusEventId: spotlight.linkedCampusEventId,
        },
      });
      if (attended) {
        return {
          sent: false,
          reason: 'Already attended linked campus event',
        };
      }
    }

    // All checks passed — send notification
    const data: Record<string, string> = { spotlightId: spotlight.id };
    if (spotlight.linkedEventId) {
      data.linkedEventId = spotlight.linkedEventId;
    }
    if (spotlight.linkedCampusEventId) {
      data.linkedCampusEventId = spotlight.linkedCampusEventId;
    }

    const sent = await this.notificationService.sendToUser(
      userId,
      spotlight.title,
      spotlight.body,
      data,
    );

    if (sent) {
      await this.prisma.spotlightNotificationLog.create({
        data: { userId, spotlightId },
      });
    }

    return { sent, reason: sent ? undefined : 'Failed to send notification' };
  }

  // --- Admin CRUD ---

  async getAllSpotlights(): Promise<SpotlightDto[]> {
    const spotlights = await this.prisma.locationSpotlight.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return spotlights.map(s => this.toDto(s));
  }

  async createSpotlight(dto: Omit<SpotlightDto, 'id'>): Promise<SpotlightDto> {
    const spotlight = await this.prisma.locationSpotlight.create({
      data: {
        title: dto.title,
        body: dto.body,
        latitude: dto.latitude,
        longitude: dto.longitude,
        radiusMeters: dto.radiusMeters,
        cooldownDays: dto.cooldownDays,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        startHour: dto.startHour,
        endHour: dto.endHour,
        isActive: dto.isActive,
        linkedEventId: dto.linkedEventId || null,
        linkedCampusEventId: dto.linkedCampusEventId || null,
      },
    });
    return this.toDto(spotlight);
  }

  async updateSpotlight(dto: SpotlightDto): Promise<SpotlightDto> {
    const spotlight = await this.prisma.locationSpotlight.update({
      where: { id: dto.id },
      data: {
        title: dto.title,
        body: dto.body,
        latitude: dto.latitude,
        longitude: dto.longitude,
        radiusMeters: dto.radiusMeters,
        cooldownDays: dto.cooldownDays,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        startHour: dto.startHour,
        endHour: dto.endHour,
        isActive: dto.isActive,
        linkedEventId: dto.linkedEventId || null,
        linkedCampusEventId: dto.linkedCampusEventId || null,
      },
    });
    return this.toDto(spotlight);
  }

  async deleteSpotlight(id: string): Promise<boolean> {
    await this.prisma.locationSpotlight.delete({ where: { id } });
    return true;
  }

  private getCampusHour(date: Date): number {
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: CAMPUS_TIMEZONE,
      hour: 'numeric',
      hour12: false,
    });
    return parseInt(formatter.format(date), 10);
  }

  private getStartOfCampusDay(date: Date): Date {
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: CAMPUS_TIMEZONE,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
    const parts = formatter.formatToParts(date);
    const year = parts.find(p => p.type === 'year')!.value;
    const month = parts.find(p => p.type === 'month')!.value;
    const day = parts.find(p => p.type === 'day')!.value;

    // Create a date at midnight in campus timezone
    const midnightStr = `${year}-${month}-${day}T00:00:00`;
    // Use a temporary date to compute the offset
    const tempDate = new Date(midnightStr + 'Z');
    const offsetMs = this.getTimezoneOffsetMs(tempDate);
    return new Date(tempDate.getTime() + offsetMs);
  }

  private getTimezoneOffsetMs(date: Date): number {
    const utcStr = date.toLocaleString('en-US', { timeZone: 'UTC' });
    const tzStr = date.toLocaleString('en-US', {
      timeZone: CAMPUS_TIMEZONE,
    });
    return new Date(utcStr).getTime() - new Date(tzStr).getTime();
  }

  private toDto(spotlight: any): SpotlightDto {
    return {
      id: spotlight.id,
      title: spotlight.title,
      body: spotlight.body,
      latitude: spotlight.latitude,
      longitude: spotlight.longitude,
      radiusMeters: spotlight.radiusMeters,
      cooldownDays: spotlight.cooldownDays,
      startDate: spotlight.startDate.toISOString(),
      endDate: spotlight.endDate.toISOString(),
      startHour: spotlight.startHour,
      endHour: spotlight.endHour,
      isActive: spotlight.isActive,
      linkedEventId: spotlight.linkedEventId ?? undefined,
      linkedCampusEventId: spotlight.linkedCampusEventId ?? undefined,
    };
  }
}
