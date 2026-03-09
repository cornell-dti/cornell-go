import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { UserGuard } from '../auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { EventSyncService } from './event-sync.service';
import {
  TriggerEventSyncDto,
  UpdateEventSyncStatusDto,
  EventSyncResultDto,
} from './event-sync.dto';
import { PoliciesGuard } from '../casl/policy.guard';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class EventSyncGateway {
  private lastResult: EventSyncResultDto | null = null;
  private running = false;

  constructor(
    private readonly clientService: ClientService,
    private readonly eventSyncService: EventSyncService,
  ) {}

  @SubscribeMessage('triggerEventSync')
  async triggerEventSync(
    @CallingUser() user: User,
    @MessageBody() data: TriggerEventSyncDto,
  ) {
    if (!user.administrator) {
      await this.clientService.emitErrorData(
        user,
        'Only administrators can trigger event sync',
      );
      return null;
    }

    if (this.running) {
      await this.clientService.emitErrorData(user, 'Event sync already in progress');
      return null;
    }

    this.running = true;

    try {
      const stats = await this.eventSyncService.syncEvents(data.days);
      this.lastResult = {
        ...stats,
        syncedAt: new Date().toISOString(),
      };
      return this.lastResult;
    } finally {
      this.running = false;
    }
  }

  @SubscribeMessage('requestEventSyncStatus')
  async requestEventSyncStatus(
    @CallingUser() user: User,
  ): Promise<UpdateEventSyncStatusDto> {
    if (!user.administrator) {
      await this.clientService.emitErrorData(
        user,
        'Only administrators can view sync status',
      );
      return { running: false, lastResult: null };
    }

    return {
      running: this.running,
      lastResult: this.lastResult,
    };
  }
}
