import { Test, TestingModule } from '@nestjs/testing';
import { ClubSubmissionService } from './club-submission.service';
import { PrismaService } from '../prisma/prisma.service';
import { ClubSubmissionDto } from './club-submission.dto';

const prismaMock: any = {
  campusEvent: {
    create: jest.fn(),
    findMany: jest.fn(),
    update: jest.fn(),
  },
} as unknown as PrismaService;

describe('ClubSubmissionService', () => {
  let service: ClubSubmissionService;

  beforeEach(async () => {
    (prismaMock.campusEvent.create as jest.Mock).mockReset();
    (prismaMock.campusEvent.findMany as jest.Mock).mockReset();
    (prismaMock.campusEvent.update as jest.Mock).mockReset();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ClubSubmissionService,
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    service = module.get<ClubSubmissionService>(ClubSubmissionService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('createClubSubmission', () => {
    it('creates a CampusEvent with correct data', async () => {
      const dto: ClubSubmissionDto = {
        clubName: 'BreakFree at Cornell',
        contactEmail: 'dance@gmail.com',
        eventTitle: 'Dance Showcase',
        description: 'Watch BreakFree perform',
        startTime: '2025-03-01T18:00:00.000Z',
        endTime: '2025-03-01T20:00:00.000Z',
        location: 'Bailey Hall',
        latitude: 42.0,
        longitude: -76.0,
        category: 'SOCIAL' as any,
        address: 'Some address',
        imageUrl: 'https://example.com/image.png',
        registrationLink: 'https://example.com/register',
      };

      const createdEvent = { id: 'event-1', title: dto.eventTitle } as any;
      (prismaMock.campusEvent.create as jest.Mock).mockResolvedValue(
        createdEvent,
      );

      const result = await service.createClubSubmission(dto);

      expect(prismaMock.campusEvent.create).toHaveBeenCalledTimes(1);
      const callArg = (prismaMock.campusEvent.create as jest.Mock).mock
        .calls[0][0];

      expect(callArg.data).toMatchObject({
        title: dto.eventTitle,
        description: dto.description,
        imageUrl: dto.imageUrl,
        locationName: dto.location,
        address: dto.address,
        latitude: dto.latitude,
        longitude: dto.longitude,
        categories: [dto.category],
        tags: [],
        organizerName: dto.clubName,
        organizerEmail: dto.contactEmail,
        registrationUrl: dto.registrationLink,
        approvalStatus: 'PENDING',
        source: 'COMMUNITY_SUBMITTED',
      });

      expect(result).toBe(createdEvent);
    });
  });

  describe('getPendingEvents', () => {
    it('returns events with approvalStatus PENDING', async () => {
      const events = [{ id: '1' }, { id: '2' }] as any[];
      (prismaMock.campusEvent.findMany as jest.Mock).mockResolvedValue(events);

      const result = await service.getPendingEvents();

      expect(prismaMock.campusEvent.findMany).toHaveBeenCalledWith({
        where: { approvalStatus: 'PENDING' },
        orderBy: { createdAt: 'asc' },
      });
      expect(result).toBe(events);
    });
  });

  describe('approveEvent', () => {
    it('sets approvalStatus to APPROVED and clears rejectionReason', async () => {
      const updatedEvent = {
        id: 'event-1',
        approvalStatus: 'APPROVED',
      } as any;
      (prismaMock.campusEvent.update as jest.Mock).mockResolvedValue(
        updatedEvent,
      );

      const result = await service.approveEvent('event-1');

      expect(prismaMock.campusEvent.update).toHaveBeenCalledWith({
        where: { id: 'event-1' },
        data: {
          approvalStatus: 'APPROVED',
          rejectionReason: null,
        },
      });
      expect(result).toBe(updatedEvent);
    });
  });

  describe('rejectEvent', () => {
    it('sets approvalStatus to REJECTED and sets rejectionReason', async () => {
      const updatedEvent = {
        id: 'event-1',
        approvalStatus: 'REJECTED',
      } as any;
      (prismaMock.campusEvent.update as jest.Mock).mockResolvedValue(
        updatedEvent,
      );

      const result = await service.rejectEvent('event-1', 'Not appropriate');

      expect(prismaMock.campusEvent.update).toHaveBeenCalledWith({
        where: { id: 'event-1' },
        data: {
          approvalStatus: 'REJECTED',
          rejectionReason: 'Not appropriate',
        },
      });
      expect(result).toBe(updatedEvent);
    });
  });
});
