import { Controller } from '@nestjs/common';
/**
 * REST controller that accepts google form data and creates a CampusEvent with PENDING approvalStatus. 
 */
@Controller('club-submission')
export class ClubSubmissionController {
    constructor(private clubSubmissionService: ClubSubmissionService) {}
    
    @Post
    async submit(@Body) dto: ClubSubmissionDto) {
        const campusEvent = await this.clubSubmissionService.createClubSubmission(dto);
        return {
            message: "Your event has been submitted and will be reviewed by an admin.",
            id: campusEvent.id,
            title: campusEvent.title
        }
    }
}
