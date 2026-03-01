import { CampusEventCategory } from '@prisma/client';

/**
 * DTO for club submission data (matches Google Form)
 * Creates a CampusEvent with approvalStatus = PENDING
 */
export interface ClubSubmissionDto {
    clubName: string; 
    contactEmail: string; 
    eventTitle: string; 
    description: string; 
    startTime: string; 
    endTime: string; 
    location: string; 
    category: CampusEventCategory; 
    imageUrl?: string; 
    registrationLink? string; 
    latitude?: number; 
    longtitude?: number; 
}