import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ClubSubmissionService } from './club-submission.service';
import { ClubSubmissionDto } from './club-submission.dto';
import { ClubSubmissionApiGuard } from './club-submission-api.guard';

/**
 * REST controller that accepts google form data and creates a CampusEvent with PENDING approvalStatus. 
 */
@Controller('api/club-submission')
export class ClubSubmissionController {
    constructor(private clubSubmissionService: ClubSubmissionService) {}
    
    @UseGuards(ClubSubmissionApiGuard)
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
