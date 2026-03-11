import { Injectable } from '@nestjs/common';
import { ApprovalStatus, EventSource } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ClubSubmissionDto } from './club-submission.dto';

const DEFAULT_LAT = 42.4534;
const DEFAULT_LONG = -76.4735;
/**
 * Build admin-facing service methods:
 * get all pending events,
 * approve an event (sets status to APPROVED),
 * reject with a reason (sets status to REJECTED).
 *
 */
@Injectable()
export class ClubSubmissionService {
  constructor(private prisma: PrismaService) {}

  /**
   * Creates a CampusEvent from ClubSubmission Google Form data
   * sets approvalStatus to PENDING and EventSource to COMMUNITY_SUBMITTED
   */
  async createClubSubmission(dto: ClubSubmissionDto) {
    return this.prisma.campusEvent.create({
      data: {
        title: dto.eventTitle,
        description: dto.description,
        imageUrl: dto.imageUrl ?? null,

        startTime: new Date(dto.startTime),
        endTime: new Date(dto.endTime),

        locationName: dto.location,
        address: dto.address ?? null,
        latitude: dto.latitude ?? DEFAULT_LAT,
        longitude: dto.longitude ?? DEFAULT_LONG,

        categories: [dto.category],
        tags: [],

        organizerName: dto.clubName,
        organizerEmail: dto.contactEmail,
        registrationUrl: dto.registrationLink ?? null,

        approvalStatus: ApprovalStatus.PENDING,
        source: EventSource.COMMUNITY_SUBMITTED,
      },
    });
  }

  async getPendingEvents() {
    return this.prisma.campusEvent.findMany({
      where: { approvalStatus: ApprovalStatus.PENDING },
      orderBy: { createdAt: 'asc' }, //orders in time created (oldest to newest)
    });
  }

  // approve an event (sets status to approved)
  async approveEvent(id: string) {
    return this.prisma.campusEvent.update({
      where: { id },
      data: {
        approvalStatus: ApprovalStatus.APPROVED,
        rejectionReason: null,
      },
    });
  }

  // reject with a reason (sets status to rejected)
  async rejectEvent(id: string, reason: string) {
    return this.prisma.campusEvent.update({
      where: { id },
      data: {
        approvalStatus: ApprovalStatus.REJECTED,
        rejectionReason: reason,
      },
    });
  }
}
