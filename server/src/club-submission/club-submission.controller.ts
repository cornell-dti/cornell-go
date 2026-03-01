import { Body, Controller, Post } from '@nestjs/common';
import { ClubSubmissionService } from './club-submission.service';
import { ClubSubmissionDto } from './club-submission.dto';

/**
 * REST controller that accepts google form data and creates a CampusEvent with PENDING approvalStatus. 
 */
@Controller('api/club-submission')
export class ClubSubmissionController {
    constructor(private clubSubmissionService: ClubSubmissionService) {}
    
    @Post()
    async submit(@Body() dto: ClubSubmissionDto) {
        const campusEvent = await this.clubSubmissionService.createClubSubmission(dto);
        return {
            message: "Your event has been submitted and will be reviewed by an admin.",
            id: campusEvent.id,
            title: campusEvent.title,
        };
    }
}
