/** DTO for updating a user's push notification token */
export interface UpdatePushTokenDto {
  fcmToken: string;
}

/** DTO for sending a notification to specific users */
export interface SendNotificationDto {
  /** Title of the notification */
  title: string;

  /** Body/message of the notification */
  body: string;

  /** Optional: specific user IDs to send to. If empty, sends to all users */
  userIds?: string[];

  /** Optional: organization ID to send to all members */
  organizationId?: string;

  /** Optional: additional data payload */
  data?: Record<string, string>;
}

/** DTO for notification send result */
export interface NotificationResultDto {
  /** Number of notifications successfully sent */
  successCount: number;

  /** Number of notifications that failed */
  failureCount: number;

  /** Error messages if any */
  errors?: string[];
}
