import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { UserGuard } from '../auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { NotificationService } from './notification.service';
import {
  UpdatePushTokenDto,
  SendNotificationDto,
  NotificationResultDto,
} from './notification.dto';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class NotificationGateway {
  constructor(private notificationService: NotificationService) {}

  /**
   * Update the FCM token for push notifications
   * Called by the Flutter app when it gets a new token
   */
  @SubscribeMessage('updateFcmToken')
  async updateFcmToken(
    @CallingUser() user: User,
    @MessageBody() data: UpdatePushTokenDto,
  ): Promise<boolean> {
    try {
      await this.notificationService.savePushToken(user.id, data.fcmToken);
      return true;
    } catch (error) {
      console.error('Error updating FCM token:', error);
      return false;
    }
  }

  /**
   * Send a notification (admin only)
   * Used by the admin panel to send manual notifications
   */
  @SubscribeMessage('sendNotification')
  async sendNotification(
    @CallingUser() user: User,
    @MessageBody() data: SendNotificationDto,
  ): Promise<NotificationResultDto | null> {
    // Only administrators can send notifications
    if (!user.administrator) {
      console.warn(`Non-admin user ${user.id} attempted to send notification`);
      return null;
    }

    try {
      const result = await this.notificationService.sendNotification(data);
      console.log(
        `Admin ${user.username} sent notification: "${data.title}" - ${result.successCount} delivered`,
      );
      return result;
    } catch (error: unknown) {
      console.error('Error sending notification:', error);
      return {
        successCount: 0,
        failureCount: 0,
        errors: [error instanceof Error ? error.message : 'Unknown error'],
      };
    }
  }

  /**
   * Remove FCM token (e.g., on logout)
   */
  @SubscribeMessage('removeFcmToken')
  async removeFcmToken(@CallingUser() user: User): Promise<boolean> {
    try {
      await this.notificationService.removePushToken(user.id);
      return true;
    } catch (error) {
      console.error('Error removing FCM token:', error);
      return false;
    }
  }
}
