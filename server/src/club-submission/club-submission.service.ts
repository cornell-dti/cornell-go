import { Injectable } from '@nestjs/common';
/**
 * Build admin-facing service methods: 
 * get all pending events, 
 * approve an event (sets status to APPROVED), 
 * reject with a reason (sets status to REJECTED). 
 * 
 */
@Injectable()
export class ClubSubmissionService {
    constructor(
        private  prisma: PrismaService
    ){}

    /**
     * Creates a CampusEvent from ClubSubmission Google Form data
     * sets approvalStatus to PENDING and EventSource to COMMUNITY_SUBMITTED
     */
    async createClubSubmission(dto: ClubSubmissionDto) {
        const campusEvent: CampusEvent =  this.prisma.campusEvent.create({
            data: {
                title: dto.eventTitle,
                description: dto.description,
                imageUrl: dto.imageUrl ?? null, 

                startTime: new Date(dto.startTime),
                endTime: new Date(dto.endTime),

                locationName: dto.location,
                address: dto.address ?? null,
                latitude: dto.latitude ?? null, // TODO: create default lat/long
                longitude: dto.longtitude ?? null,

                category: [dto.category],
                tags: [],

                organizerName: dto.clubName,
                organizerEmail: dto.contactEmail,
                registrationUrl: dto.registrationLink ?? null,

                approvalStatus: ApprovalStatus.PENDING,
                source: EventSource.COMMUNITY_SUBMITTED

            }
        }

        )
        console.log(`CampusEvent created`);
    
        return campusEvent
    }
}
