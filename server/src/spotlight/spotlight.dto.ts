/** Full spotlight data for admin CRUD */
export interface SpotlightDto {
  id: string;
  title: string;
  body: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  cooldownDays: number;
  startDate: string;
  endDate: string;
  startHour: number;
  endHour: number;
  isActive: boolean;
  linkedEventId?: string;
  linkedCampusEventId?: string;
}

/** Lightweight spotlight data sent to Flutter for proximity checks */
export interface ActiveSpotlightDto {
  id: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
}

/** Client request to trigger a spotlight notification */
export interface RequestSpotlightNotificationDto {
  spotlightId: string;
  latitude: number;
  longitude: number;
}

/** Response for a spotlight notification request */
export interface SpotlightNotificationResultDto {
  sent: boolean;
  reason?: string;
}

/** DTO for deleting a spotlight */
export interface DeleteSpotlightDto {
  id: string;
}
