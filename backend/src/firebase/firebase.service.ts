import { Injectable, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private messaging: admin.messaging.Messaging;

  onModuleInit() {
    // Initialize Firebase Admin
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        }),
      });
    }

    this.messaging = admin.messaging();
    console.log('🔥 Firebase Admin initialized');
  }

  async sendPushNotification(
    deviceToken: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ) {
    try {
      const message = {
        notification: {
          title,
          body,
        },
        data: data || {},
        token: deviceToken,
      };

      const response = await this.messaging.send(message);
      console.log('📱 Push notification sent:', response);
      return response;
    } catch (error) {
      console.error('❌ Failed to send push notification:', error);
      throw error;
    }
  }

  async sendMulticastNotification(
    deviceTokens: string[],
    title: string,
    body: string,
    data?: Record<string, string>,
  ) {
    try {
      const message = {
        notification: {
          title,
          body,
        },
        data: data || {},
        tokens: deviceTokens,
      };

      const response = await this.messaging.sendEachForMulticast(message);
      console.log('📱 Multicast notification sent:', response.successCount);
      return response;
    } catch (error) {
      console.error('❌ Failed to send multicast notification:', error);
      throw error;
    }
  }
}
