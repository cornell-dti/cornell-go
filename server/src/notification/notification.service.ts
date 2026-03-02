import { Injectable, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { PrismaService } from '../prisma/prisma.service';
import { SendNotificationDto, NotificationResultDto } from './notification.dto';

@Injectable()
export class NotificationService implements OnModuleInit {
  private firebaseApp: admin.app.App | null = null;

  constructor(private prisma: PrismaService) {}

  onModuleInit() {
    this.initializeFirebase();
  }

  /**
   * Initialize Firebase Admin SDK
   * Requires FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY env vars
   */
  private initializeFirebase() {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

    if (!projectId || !clientEmail || !privateKey) {
      console.warn(
        'Firebase credentials not configured. Push notifications will be disabled.',
      );
      console.warn(
        'Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY env vars to enable.',
      );
      return;
    }

    try {
      this.firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey,
        }),
      });
      console.log('Firebase Admin SDK initialized successfully');
    } catch (error) {
      console.error('Failed to initialize Firebase Admin SDK:', error);
    }
  }

  /**
   * Check if Firebase is properly initialized
   */
  isInitialized(): boolean {
    return this.firebaseApp !== null;
  }

  /**
   * Save or update a user's FCM token
   */
  async savePushToken(userId: string, fcmToken: string): Promise<void> {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
    console.log(`Updated FCM token for user ${userId}`);
  }

  /**
   * Remove a user's FCM token (e.g., on logout)
   */
  async removePushToken(userId: string): Promise<void> {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken: null },
    });
  }

  /**
   * Send notification to a single user by their ID
   */
  async sendToUser(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });

    if (!user?.fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return false;
    }

    return this.sendToToken(user.fcmToken, title, body, data);
  }

  /**
   * Send notification to a specific FCM token
   */
  async sendToToken(
    token: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<boolean> {
    if (!this.firebaseApp) {
      console.warn('Firebase not initialized, cannot send notification');
      return false;
    }

    try {
      const message: admin.messaging.Message = {
        token,
        notification: {
          title,
          body,
        },
        data,
        // Android-specific config
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'default',
          },
        },
        // iOS-specific config
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log('Successfully sent notification:', response);
      return true;
    } catch (error: unknown) {
      console.error('Error sending notification:', error);
      // If token is invalid, remove it from the database
      const firebaseError = error as { code?: string };
      if (
        firebaseError.code === 'messaging/invalid-registration-token' ||
        firebaseError.code === 'messaging/registration-token-not-registered'
      ) {
        await this.prisma.user.updateMany({
          where: { fcmToken: token },
          data: { fcmToken: null },
        });
      }
      return false;
    }
  }

  /**
   * Send notification to all users with valid FCM tokens
   */
  async sendToAllUsers(
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<NotificationResultDto> {
    const users = await this.prisma.user.findMany({
      where: {
        fcmToken: { not: null },
        isBanned: false,
      },
      select: { fcmToken: true },
    });

    return this.sendToTokens(
      users.map(u => u.fcmToken!),
      title,
      body,
      data,
    );
  }

  /**
   * Send notification to all members of an organization
   */
  async sendToOrganization(
    organizationId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<NotificationResultDto> {
    const org = await this.prisma.organization.findUnique({
      where: { id: organizationId },
      include: {
        members: {
          where: {
            fcmToken: { not: null },
            isBanned: false,
          },
          select: { fcmToken: true },
        },
      },
    });

    if (!org) {
      return {
        successCount: 0,
        failureCount: 0,
        errors: ['Organization not found'],
      };
    }

    return this.sendToTokens(
      org.members.map(m => m.fcmToken!),
      title,
      body,
      data,
    );
  }

  /**
   * Send notification to multiple tokens using multicast
   */
  private async sendToTokens(
    tokens: string[],
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<NotificationResultDto> {
    if (!this.firebaseApp) {
      return {
        successCount: 0,
        failureCount: tokens.length,
        errors: ['Firebase not initialized'],
      };
    }

    if (tokens.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    // Firebase multicast has a limit of 500 tokens per request
    const batchSize = 500;
    let successCount = 0;
    let failureCount = 0;
    const errors: string[] = [];
    const invalidTokens: string[] = [];

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);

      try {
        const message: admin.messaging.MulticastMessage = {
          tokens: batch,
          notification: {
            title,
            body,
          },
          data,
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'default',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        successCount += response.successCount;
        failureCount += response.failureCount;

        // Track invalid tokens for cleanup
        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            if (
              resp.error.code === 'messaging/invalid-registration-token' ||
              resp.error.code === 'messaging/registration-token-not-registered'
            ) {
              invalidTokens.push(batch[idx]);
            }
          }
        });
      } catch (error: unknown) {
        console.error('Error sending batch notification:', error);
        failureCount += batch.length;
        errors.push(error instanceof Error ? error.message : 'Unknown error');
      }
    }

    // Clean up invalid tokens
    if (invalidTokens.length > 0) {
      await this.prisma.user.updateMany({
        where: { fcmToken: { in: invalidTokens } },
        data: { fcmToken: null },
      });
      console.log(`Cleaned up ${invalidTokens.length} invalid FCM tokens`);
    }

    console.log(
      `Notification sent: ${successCount} success, ${failureCount} failed`,
    );

    return {
      successCount,
      failureCount,
      errors: errors.length > 0 ? errors : undefined,
    };
  }

  /**
   * Send notification based on DTO (used by admin panel)
   */
  async sendNotification(
    dto: SendNotificationDto,
  ): Promise<NotificationResultDto> {
    const { title, body, userIds, organizationId, data } = dto;

    // Send to specific organization
    if (organizationId) {
      return this.sendToOrganization(organizationId, title, body, data);
    }

    // Send to specific users
    if (userIds && userIds.length > 0) {
      const users = await this.prisma.user.findMany({
        where: {
          id: { in: userIds },
          fcmToken: { not: null },
          isBanned: false,
        },
        select: { fcmToken: true },
      });

      return this.sendToTokens(
        users.map(u => u.fcmToken!),
        title,
        body,
        data,
      );
    }

    // Send to all users
    return this.sendToAllUsers(title, body, data);
  }
}
