import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import axios, { AxiosInstance } from 'axios';
import { PrismaService } from '../prisma/prisma.service';
import {
  ApprovalStatus,
  CampusEventCategory,
  EventSource,
} from '@prisma/client';

const LOCALIST_BASE_URL = 'https://events.cornell.edu/api/2';
const SYNC_ON_STARTUP = false; // Set to true to run initial sync on startup
const SYNC_CRON = CronExpression.EVERY_6_HOURS; // tunable param, maybe set to EVERY_DAY_AT_MIDNIGHT instead
const SYNC_WINDOW_DAYS = 7;
const PAGE_SIZE = 100;
const REQUEST_DELAY_MS = 1500;
const CORNELL_DEFAULT_LAT = 42.4534; // Default latitude for events without geolocation (arts quad)
const CORNELL_DEFAULT_LNG = -76.4735; // Default longitude for events without geolocation

interface LocalistGeo {
  latitude?: string;
  longitude?: string;
  street?: string;
  city?: string;
  state?: string;
  country?: string;
  zip?: string;
}

interface LocalistEventInstance {
  event_instance: {
    id: number;
    start: string;
    end: string | null;
    all_day: boolean;
    event_id: number;
  };
}

interface LocalistFilterItem {
  id: number;
  name: string;
}

interface LocalistEvent {
  id: number;
  title: string;
  description_text?: string;
  description?: string;
  photo_url?: string;
  location_name?: string;
  location?: string;
  address?: string;
  geo?: LocalistGeo;
  tags?: string[];
  keywords?: string[];
  filters?: {
    event_types?: LocalistFilterItem[];
    departments?: LocalistFilterItem[];
  };
  groups?: Array<{ id: number; name: string }>;
  localist_url?: string;
  ticket_url?: string;
  featured?: boolean;
  updated_at?: string;
  event_instances?: LocalistEventInstance[];
}

interface LocalistPage {
  current: number;
  size: number;
  total: number;
}

interface LocalistEventsResponse {
  events: Array<{ event: LocalistEvent }>;
  page: LocalistPage;
}

const EVENT_TYPE_CATEGORY_MAP: Record<string, CampusEventCategory> = {
  'athletic': CampusEventCategory.ATHLETIC,
  'music': CampusEventCategory.ARTS,
  'performance': CampusEventCategory.ARTS,
  'film': CampusEventCategory.ARTS,
  'dance (performance)': CampusEventCategory.ARTS,
  'arts & culture': CampusEventCategory.CULTURAL,
  'cultural': CampusEventCategory.CULTURAL,
  'exhibit': CampusEventCategory.CULTURAL,
  'exhibition': CampusEventCategory.CULTURAL,
  'seminar': CampusEventCategory.ACADEMIC,
  'lecture': CampusEventCategory.ACADEMIC,
  'class/ workshop': CampusEventCategory.ACADEMIC,
  'colloquium': CampusEventCategory.ACADEMIC,
  'webinar': CampusEventCategory.ACADEMIC,
  'research': CampusEventCategory.ACADEMIC,
  'symposium': CampusEventCategory.ACADEMIC,
  'presentation': CampusEventCategory.ACADEMIC,
  'panel discussion': CampusEventCategory.ACADEMIC,
  'training': CampusEventCategory.ACADEMIC,
  'career': CampusEventCategory.CAREER,
  'networking': CampusEventCategory.CAREER,
  'fair': CampusEventCategory.CAREER,
  'community forum': CampusEventCategory.COMMUNITY,
  'special event': CampusEventCategory.COMMUNITY,
  'conference': CampusEventCategory.COMMUNITY,
  'conference/workshop': CampusEventCategory.COMMUNITY,
  'charity/fundraiser': CampusEventCategory.COMMUNITY,
  'meeting': CampusEventCategory.SOCIAL,
  'food/catering': CampusEventCategory.SOCIAL,
  'dance (social)': CampusEventCategory.SOCIAL,
  'wellness': CampusEventCategory.WELLNESS,
};

@Injectable()
export class EventSyncService implements OnModuleInit {
  private readonly logger = new Logger(EventSyncService.name);
  private readonly http: AxiosInstance;

  constructor(private readonly prisma: PrismaService) {
    this.http = axios.create({
      baseURL: LOCALIST_BASE_URL,
      timeout: 15000,
    });
  }

  async onModuleInit() {
    if (SYNC_ON_STARTUP) {
      this.logger.log('SYNC_ON_STARTUP is enabled — running initial event sync now');
      this.syncEvents().catch((err) =>
        this.logger.error('Initial sync failed', err instanceof Error ? err.stack : err),
      );
    } else {
      this.logger.log(
        'EventSyncService initialized — first sync will run on next cron tick',
      );
    }
  }

  @Cron(SYNC_CRON)
  async handleScheduledSync() {
    this.logger.log('Scheduled event sync starting');
    await this.syncEvents();
  }

  async syncEvents(
    days?: number,
  ): Promise<{ created: number; updated: number; archived: number; totalFetched: number }> {
    const stats = { created: 0, updated: 0, archived: 0, totalFetched: 0 };

    try {
      const events = await this.fetchAllEvents(days);
      stats.totalFetched = events.length;
      this.logger.log(`Fetched ${events.length} events from Localist`);

      for (const localistEvent of events) {
        const result = await this.upsertEvent(localistEvent);
        if (result === 'created') stats.created++;
        else if (result === 'updated') stats.updated++;
      }

      stats.archived = await this.archivePastEvents();

      this.logger.log(
        `Sync complete — created: ${stats.created}, updated: ${stats.updated}, archived: ${stats.archived}`,
      );
    } catch (error) {
      this.logger.error('Event sync failed', error instanceof Error ? error.stack : error);
    }

    return stats;
  }

  private async fetchAllEvents(days?: number): Promise<LocalistEvent[]> {
    const allEvents: LocalistEvent[] = [];
    const startDate = this.formatDate(new Date());
    let currentPage = 1;
    let totalPages = 1;

    do {
      const response = await this.http.get<LocalistEventsResponse>('/events', {
        params: {
          start: startDate,
          days: days ?? SYNC_WINDOW_DAYS,
          pp: PAGE_SIZE,
          page: currentPage,
        },
      });

      const { events, page } = response.data;
      totalPages = page.total;

      for (const wrapper of events) {
        allEvents.push(wrapper.event);
      }

      this.logger.debug(`Fetched page ${currentPage}/${totalPages} (${events.length} events)`);
      currentPage++;

      if (currentPage <= totalPages) {
        await this.delay(REQUEST_DELAY_MS);
      }
    } while (currentPage <= totalPages);

    return allEvents;
  }

  private async upsertEvent(
    localistEvent: LocalistEvent,
  ): Promise<'created' | 'updated' | 'skipped'> {
    const externalId = String(localistEvent.id);

    const existing = await this.prisma.campusEvent.findUnique({
      where: { externalId },
    });

    const localistUpdatedAt = localistEvent.updated_at
      ? new Date(localistEvent.updated_at)
      : null;

    if (existing && localistUpdatedAt && existing.updatedAt >= localistUpdatedAt) {
      return 'skipped';
    }

    const data = this.mapLocalistEvent(localistEvent);

    if (existing) {
      await this.prisma.campusEvent.update({
        where: { externalId },
        data,
      });
      return 'updated';
    }

    await this.prisma.campusEvent.create({
      data: {
        ...data,
        externalId,
        source: EventSource.API_EVENTS,
        approvalStatus: ApprovalStatus.APPROVED,
      },
    });
    return 'created';
  }

  private mapLocalistEvent(event: LocalistEvent) {
    const instance = this.pickNextInstance(event.event_instances);
    const startTime = instance ? new Date(instance.event_instance.start) : new Date();
    const endTime = instance?.event_instance.end
      ? new Date(instance.event_instance.end)
      : new Date(startTime.getTime() + 60 * 60 * 1000);
    const allDay = instance?.event_instance.all_day ?? false;

    const lat = event.geo?.latitude ? parseFloat(event.geo.latitude) : CORNELL_DEFAULT_LAT;
    const lng = event.geo?.longitude ? parseFloat(event.geo.longitude) : CORNELL_DEFAULT_LNG;

    const categories = this.mapCategories(event.filters?.event_types);
    const tags = [
      ...(event.tags ?? []),
      ...(event.keywords ?? []),
    ];

    const description = event.description_text?.trim() || 'No description available';

    const organizerName =
      event.filters?.departments?.[0]?.name ??
      event.groups?.[0]?.name ??
      null;

    return {
      title: event.title,
      description,
      imageUrl: event.photo_url || null,
      startTime,
      endTime,
      allDay,
      locationName: event.location_name || event.location || 'TBD',
      address: event.address || null,
      latitude: isNaN(lat) ? CORNELL_DEFAULT_LAT : lat,
      longitude: isNaN(lng) ? CORNELL_DEFAULT_LNG : lng,
      categories,
      tags,
      externalUrl: event.localist_url || null,
      featured: event.featured ?? false,
      registrationUrl: event.ticket_url || null,
      organizerName,
    };
  }

  private pickNextInstance(
    instances?: LocalistEventInstance[],
  ): LocalistEventInstance | undefined {
    if (!instances?.length) return undefined;

    const now = new Date();
    const upcoming = instances
      .filter((i) => new Date(i.event_instance.start) >= now)
      .sort(
        (a, b) =>
          new Date(a.event_instance.start).getTime() -
          new Date(b.event_instance.start).getTime(),
      );

    return upcoming[0] ?? instances[0];
  }

  private mapCategories(
    eventTypes?: LocalistFilterItem[],
  ): CampusEventCategory[] {
    if (!eventTypes?.length) return [CampusEventCategory.OTHER];

    const mapped = new Set<CampusEventCategory>();
    for (const type of eventTypes) {
      const category = EVENT_TYPE_CATEGORY_MAP[type.name.toLowerCase()];
      mapped.add(category ?? CampusEventCategory.OTHER);
    }
    return Array.from(mapped);
  }

  private async archivePastEvents(): Promise<number> {
    const result = await this.prisma.campusEvent.updateMany({
      where: {
        source: EventSource.API_EVENTS,
        approvalStatus: ApprovalStatus.APPROVED,
        endTime: { lt: new Date() },
      },
      data: { approvalStatus: ApprovalStatus.ARCHIVED },
    });
    return result.count;
  }

  private formatDate(date: Date): string {
    return date.toISOString().split('T')[0];
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
