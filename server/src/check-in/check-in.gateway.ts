import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { UseGuards } from '@nestjs/common';
import { User } from '@prisma/client';
import { UserGuard } from '../auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { CheckInService } from './check-in.service';
import {
  CheckInErrorDto,
  LocationCheckInDto,
  QrCodeCheckInDto,
} from './check-in.dto';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class CheckInGateway {
  constructor(private readonly checkInService: CheckInService) {}

  @SubscribeMessage('checkInWithLocation')
  async handleLocationCheckIn(
    @CallingUser() user: User,
    @MessageBody() data: LocationCheckInDto,
    @ConnectedSocket() client: Socket,
  ): Promise<boolean> {
    try {
      const result = await this.checkInService.checkInByLocation(user, data);
      client.emit('checkInSuccess', result);
      return true;
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown error occurred';
      const errorDto: CheckInErrorDto = {
        message,
        code: this.mapErrorToCode(message),
      };
      client.emit('checkInError', errorDto);
      return false;
    }
  }

  @SubscribeMessage('checkInWithQrCode')
  async handleQrCodeCheckIn(
    @CallingUser() user: User,
    @MessageBody() data: QrCodeCheckInDto,
    @ConnectedSocket() client: Socket,
  ): Promise<boolean> {
    try {
      const result = await this.checkInService.checkInByQrCode(user, data);
      client.emit('checkInSuccess', result);
      return true;
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown error occurred';
      const errorDto: CheckInErrorDto = {
        message,
        code: this.mapErrorToCode(message),
      };
      client.emit('checkInError', errorDto);
      return false;
    }
  }

  private mapErrorToCode(message: string): CheckInErrorDto['code'] {
    if (message.includes('not found')) {
      return 'EVENT_NOT_FOUND';
    }
    if (message.includes('not currently active')) {
      return 'EVENT_NOT_ACTIVE';
    }
    if (message.includes('not approved')) {
      return 'EVENT_NOT_APPROVED';
    }
    if (message.includes('already checked in')) {
      return 'ALREADY_CHECKED_IN';
    }
    if (message.includes('within check-in radius')) {
      return 'OUT_OF_RADIUS';
    }
    if (message.includes('not allowed')) {
      return 'METHOD_NOT_ALLOWED';
    }
    if (message.includes('Invalid or unknown QR code')) {
      return 'INVALID_QR_CODE';
    }
    return 'UNKNOWN_ERROR';
  }
}

