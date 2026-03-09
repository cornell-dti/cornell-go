import { Injectable } from '@nestjs/common';
import { User } from '@prisma/client';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { EventService } from '../event/event.service';
import { UserService } from '../user/user.service';
import { v4 as uuidv4 } from 'uuid';
import {
  CheckInResultDto,
  LocationCheckInDto,
  QrCodeCheckInDto,
  CheckInMethodDto,
} from './check-in.dto';

@Injectable()
export class CheckInService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventService: EventService,
    private readonly userService: UserService,
  ) {}

  private toRadians(degrees: number): number {
    return (degrees * Math.PI) / 180;
  }

  private calculateDistanceInMeters(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371000;
    const dLat = this.toRadians(lat2 - lat1);
    const dLon = this.toRadians(lon2 - lon1);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRadians(lat1)) *
        Math.cos(this.toRadians(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  private ensureEventActive(event: any) {
    const now = new Date();
    if (now < event.startTime || now > event.endTime) {
      throw new Error('Event is not currently active for check-in');
    }
    if (event.approvalStatus !== 'APPROVED') {
      throw new Error('Event is not approved for check-in');
    }
  }

  private ensureMethodAllowed(event: any, method: CheckInMethodDto) {
    if (
      event.checkInMethod !== 'EITHER' &&
      event.checkInMethod !== method
    ) {
      throw new Error('This check-in method is not allowed for this event');
    }
  }

  /**
   * Create EventAttendance. Throws 'User has already checked in to this event'
   * on unique constraint violation (P2002) to avoid TOCTOU race when two requests run concurrently.
   */
  private async createAttendance(
    userId: string,
    campusEventId: string,
    checkInMethod: 'LOCATION' | 'QR_CODE',
    pointsAwarded: number,
  ): Promise<{ id: string }> {
    try {
      const attendance = await (this.prisma as any).eventAttendance.create({
        data: {
          userId,
          campusEventId,
          checkInMethod,
          pointsAwarded,
        },
      });
      return attendance;
    } catch (err) {
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        throw new Error('User has already checked in to this event');
      }
      throw err;
    }
  }

  private async awardPoints(
    user: User,
    points: number,
  ): Promise<{ newTotalScore: number }> {
    if (points <= 0) {
      const current = await this.prisma.user.findUniqueOrThrow({
        where: { id: user.id },
        select: { score: true },
      });
      return { newTotalScore: current.score };
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: user.id },
      data: { score: { increment: points } },
    });

    const eventTracker =
      await this.eventService.getCurrentEventTrackerForUser(user);
    const updatedTracker = await this.prisma.eventTracker.update({
      where: { id: eventTracker.id },
      data: { score: { increment: points } },
    });

    await this.eventService.emitUpdateLeaderPosition({
      playerId: updatedUser.id,
      newTotalScore: updatedUser.score,
      newEventScore: updatedTracker.score,
      eventId: updatedTracker.eventId,
    });

    await this.userService.emitUpdateUserData(
      updatedUser,
      false,
      false,
      updatedUser,
    );

    return { newTotalScore: updatedUser.score };
  }

  async checkInByLocation(
    user: User,
    data: LocationCheckInDto,
  ): Promise<CheckInResultDto> {
    const event = await (this.prisma as any).campusEvent.findUnique({
      where: { id: data.campusEventId },
    });

    if (!event) {
      throw new Error('Campus event not found');
    }

    this.ensureEventActive(event);
    this.ensureMethodAllowed(event, 'LOCATION');

    const distance = this.calculateDistanceInMeters(
      data.latitude,
      data.longitude,
      event.latitude,
      event.longitude,
    );

    if (distance > event.checkInRadius) {
      throw new Error('User is not within check-in radius for this event');
    }

    const points = event.pointsForAttendance ?? 0;

    const attendance = await this.createAttendance(
      user.id,
      event.id,
      'LOCATION',
      points,
    );

    const { newTotalScore } = await this.awardPoints(user, points);

    return {
      attendanceId: attendance.id,
      campusEventId: event.id,
      checkInMethod: 'LOCATION',
      pointsAwarded: points,
      newTotalScore,
    };
  }

  async checkInByQrCode(
    user: User,
    data: QrCodeCheckInDto,
  ): Promise<CheckInResultDto> {
    const event = await (this.prisma as any).campusEvent.findFirst({
      where: { qrCode: data.qrCode },
    });

    if (!event) {
      throw new Error('Invalid or unknown QR code');
    }

    this.ensureEventActive(event);
    this.ensureMethodAllowed(event, 'QR_CODE');

    const points = event.pointsForAttendance ?? 0;

    const attendance = await this.createAttendance(
      user.id,
      event.id,
      'QR_CODE',
      points,
    );

    const { newTotalScore } = await this.awardPoints(user, points);

    return {
      attendanceId: attendance.id,
      campusEventId: event.id,
      checkInMethod: 'QR_CODE',
      pointsAwarded: points,
      newTotalScore,
    };
  }

  async generateQrCodeForEvent(eventId: string): Promise<string> {
    const event = await (this.prisma as any).campusEvent.findUnique({
      where: { id: eventId },
    });

    if (!event) {
      throw new Error('Campus event not found');
    }

    const qrCode = uuidv4();

    const updated = await (this.prisma as any).campusEvent.update({
      where: { id: event.id },
      data: { qrCode },
    });

    return updated.qrCode!;
  }
}

