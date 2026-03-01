export const CampusEventCategoryDto = {
  SOCIAL: 'SOCIAL',
  CULTURAL: 'CULTURAL',
  ATHLETIC: 'ATHLETIC',
  WELLNESS: 'WELLNESS',
  ACADEMIC: 'ACADEMIC',
  ARTS: 'ARTS',
  CAREER: 'CAREER',
  COMMUNITY: 'COMMUNITY',
  OTHER: 'OTHER',
} as const;
export type CampusEventCategoryDto =
  (typeof CampusEventCategoryDto)[keyof typeof CampusEventCategoryDto];

export const EventSourceDto = {
  API_EVENTS: 'API_EVENTS',
  ADMIN_CREATED: 'ADMIN_CREATED',
  COMMUNITY_SUBMITTED: 'COMMUNITY_SUBMITTED',
} as const;
export type EventSourceDto = (typeof EventSourceDto)[keyof typeof EventSourceDto];

export const CheckInMethodDto = {
  LOCATION: 'LOCATION',
  QR_CODE: 'QR_CODE',
  EITHER: 'EITHER',
} as const;
export type CheckInMethodDto =
  (typeof CheckInMethodDto)[keyof typeof CheckInMethodDto];

/** Core campus event DTO for API responses */
export interface CampusEventDto {
  id: string;
  title: string;
  description: string;
  imageUrl?: string;
  startTime: string;
  endTime: string;
  allDay: boolean;
  locationName: string;
  address?: string;
  latitude: number;
  longitude: number;
  categories: CampusEventCategoryDto[];
  tags: string[];
  source: EventSourceDto;
  externalUrl?: string;
  organizerName?: string;
  registrationUrl?: string;
  checkInMethod: CheckInMethodDto;
  pointsForAttendance: number;
  featured: boolean;
  attendanceCount: number;
  rsvpCount: number;
}

/** Request: paginated list of campus events with filters */
export interface RequestCampusEventsDto {
  page: number;
  limit: number;
  dateFrom?: string; // ISO 8601
  dateTo?: string;
  categories?: CampusEventCategoryDto[];
  search?: string;
  featured?: boolean;
}

/** Response: paginated list */
export interface CampusEventListDto {
  events: CampusEventDto[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

/** Request: single event details */
export interface RequestCampusEventDetailsDto {
  eventId: string;
}

/** Request: create or update event (admin) */
export interface UpsertCampusEventDto {
  id?: string; // omit for create
  title: string;
  description: string;
  imageUrl?: string;
  startTime: string;
  endTime: string;
  allDay?: boolean;
  locationName: string;
  address?: string;
  latitude: number;
  longitude: number;
  checkInRadius?: number;
  categories: CampusEventCategoryDto[];
  tags: string[];
  source: EventSourceDto;
  externalId?: string;
  externalUrl?: string;
  organizerName?: string;
  organizerEmail?: string;
  organizerId?: string;
  checkInMethod?: CheckInMethodDto;
  pointsForAttendance?: number;
  featured?: boolean;
  registrationUrl?: string;
}

/** Request: delete event */
export interface DeleteCampusEventDto {
  eventId: string;
}

/** Request: RSVP to event */
export interface RsvpCampusEventDto {
  eventId: string;
}

/** Request: remove RSVP */
export interface UnRsvpCampusEventDto {
  eventId: string;
}

/** Emit: single event update (create/update/delete) for broadcasting */
export interface UpdateCampusEventDataDto {
  event: CampusEventDto | { id: string };
  deleted: boolean;
}

/** Emit: paginated list response (for requestCampusEvents ack) */
export interface CampusEventListResponseDto {
  list: CampusEventListDto;
}
