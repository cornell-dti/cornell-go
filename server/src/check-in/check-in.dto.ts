export type CheckInMethodDto = 'LOCATION' | 'QR_CODE';

export interface LocationCheckInDto {
  campusEventId: string;
  latitude: number;
  longitude: number;
}

export interface QrCodeCheckInDto {
  qrCode: string;
}

export interface GenerateQrCodeDto {
  campusEventId: string;
}

export interface CheckInResultDto {
  attendanceId: string;
  campusEventId: string;
  checkInMethod: CheckInMethodDto;
  pointsAwarded: number;
  newTotalScore: number;
}

export type CheckInErrorCode =
  | 'EVENT_NOT_FOUND'
  | 'EVENT_NOT_ACTIVE'
  | 'EVENT_NOT_APPROVED'
  | 'ALREADY_CHECKED_IN'
  | 'OUT_OF_RADIUS'
  | 'METHOD_NOT_ALLOWED'
  | 'INVALID_QR_CODE'
  | 'UNKNOWN_ERROR';

export interface CheckInErrorDto {
  message: string;
  code: CheckInErrorCode;
}
