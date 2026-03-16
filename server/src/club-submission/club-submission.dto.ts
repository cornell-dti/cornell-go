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
  location: string; // location/venue name
  latitude?: number;
  longitude?: number;
  category: CampusEventCategory;
  address?: string;
  imageUrl?: string;
  registrationLink?: string;
}
