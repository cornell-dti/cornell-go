import { Controller } from '@nestjs/common';
/**
 * - 
- Build a REST controller (not WebSocket — this receives HTTP POST requests) with an endpoint 
like `POST /api/club-submissions` that accepts the form data and creates a `CampusEvent` with 
`approvalStatus = PENDING`. The fields it accepts will match what we put on the Google Form 
(club name, contact email, event title, description, dates, location, category, plus optional fields 
like image URL and registration link)
- Secure the endpoint with an API key header (`x-api-key`) so only our Google Form script can call it
 */
@Controller('club-submission')
export class ClubSubmissionController {}
