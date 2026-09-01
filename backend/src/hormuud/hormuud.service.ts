// src/sms/hormuud.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import * as crypto from 'crypto';
import { LogSanitizer } from '../common/utils/log-sanitizer.util';

// Define TypeScript interfaces for API responses
interface TokenResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  userName?: string;
}

interface SmsResponse {
  ResponseCode: string;
  ResponseMessage: string;
  Data: {
    MessageID: string;
    Description: string;
    DeliveryCallBack: string | null;
    Details: {
      TextLength: number;
      TotalCharacters: number;
      TotalSMS: number;
      IsGMS7Bit: boolean;
      ContainsUnicode: boolean;
      IsMultipart: boolean;
      ExtensionSet: unknown[];
      UnicodeSet: unknown[];
      MessageParts: string[];
    } | null;
  };
}

@Injectable()
export class HormuudService {
  private readonly logger = new Logger(HormuudService.name);
  private accessToken: string | null = null;
  private tokenExpiry: Date | null = null;
  private readonly isProduction: boolean;

  constructor(private configService: ConfigService) {
    this.isProduction = configService.get('NODE_ENV') === 'production';

    // ✅ ONLY log in development
    if (!this.isProduction) {
      const username = this.configService.get<string>('HORMUUD_USERNAME');
      const senderId = this.configService.get<string>('HORMUUD_SENDER_ID');

      this.logger.log('✅ Hormuud credentials configured');
      this.logger.log(`   Username: ${this.maskUsername(username)}`);
      this.logger.log(`   Password: ***CONFIGURED***`);
      this.logger.log(`   Sender ID: ${senderId ?? 'MISSING'}`);
    }
  }
  private maskUsername(username: string | undefined): string {
    if (!username) return 'MISSING';
    if (username.length <= 4) return '***';

    const firstTwo = username.substring(0, 2);
    const lastTwo = username.substring(username.length - 2);
    return `${firstTwo}***${lastTwo}`;
  }

  private async getAccessToken(): Promise<string> {
    // Check if token exists and hasn't expired (with 5-minute buffer)
    if (this.accessToken && this.tokenExpiry && new Date() < this.tokenExpiry) {
      this.logger.log('Using cached access token');
      return this.accessToken;
    }

    const username = this.configService.get<string>('HORMUUD_USERNAME');
    const password = this.configService.get<string>('HORMUUD_PASSWORD');

    if (!username || !password) {
      throw new Error(
        'Hormuud credentials not configured in environment variables',
      );
    }

    try {
      const params = new URLSearchParams();
      params.append('username', username);
      params.append('password', password);
      params.append('grant_type', 'password');

      this.logger.log('Requesting Hormuud access token...');

      const response = await axios.post<TokenResponse>(
        'https://smsapi.hormuud.com/token',
        params.toString(),
        {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            Accept: 'application/json',
          },
          timeout: 15000,
        },
      );

      const tokenData = response.data;
      this.accessToken = tokenData.access_token;
      this.tokenExpiry = new Date(Date.now() + 55 * 60 * 1000); // 55 minutes

      this.logger.log('✅ Successfully obtained Hormuud access token');

      // ✅ SAFE: Never log the actual token
      if (this.accessToken) {
        this.logger.log(
          `   Token: ${LogSanitizer.maskValue(this.accessToken)}`,
        );
      }

      return this.accessToken;
    } catch (error: unknown) {
      if (axios.isAxiosError(error)) {
        // ✅ SAFE: Sanitize error response before logging
        const sanitizedError = LogSanitizer.sanitize({
          status: error.response?.status,
          data: error.response?.data,
        });

        this.logger.error('Token API Error:', sanitizedError);

        const errorData = error.response?.data as
          | { error?: string }
          | undefined;

        if (errorData?.error === 'invalid_grant') {
          throw new Error(
            'Invalid Hormuud credentials. Please check HORMUUD_USERNAME and HORMUUD_PASSWORD in .env file. ' +
              'Use the API password, not your account password.',
          );
        }
      }

      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';

      // ✅ SAFE: Sanitize error message before logging
      this.logger.error(
        `Failed to get Hormuud access token: ${LogSanitizer.sanitizeString(errorMessage)}`,
      );
      throw new Error('Failed to authenticate with Hormuud SMS provider');
    }
  }

  async sendSms(phoneNumber: string, message: string): Promise<boolean> {
    try {
      const token = await this.getAccessToken();
      const formattedPhone = phoneNumber.replace('+', '');
      const senderId = this.configService.get<string>('HORMUUD_SENDER_ID');

      // ✅ SAFE: Mask phone number in logs
      this.logger.log(
        `Sending SMS to ${LogSanitizer.maskPhoneNumber(formattedPhone)}`,
      );

      const response = await axios.post<SmsResponse>(
        'https://smsapi.hormuud.com/api/SendSMS',
        {
          refid: crypto.randomUUID(),
          mobile: formattedPhone,
          message: message,
          senderid: senderId,
          mType: -1,
          eType: -1,
          validity: 0,
          delivery: 0,
          UDH: '',
          RequestDate: new Date().toISOString(),
        },
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          timeout: 15000,
        },
      );

      const smsResponse = response.data;

      // Check response for errors
      if (
        smsResponse.ResponseCode === '204' ||
        smsResponse.ResponseMessage === 'Failed.'
      ) {
        const description = smsResponse.Data?.Description ?? 'Unknown error';

        // ✅ SAFE: Sanitize description
        this.logger.error(
          `SMS sending failed: ${LogSanitizer.sanitizeString(description)}`,
        );

        if (description === 'Zero Balance!!') {
          throw new Error(
            'Hormuud SMS account has zero balance. Please add SMS credit.',
          );
        }

        throw new Error(`SMS sending failed: ${description}`);
      }

      // ✅ SAFE: Mask phone in success log
      this.logger.log(
        `✅ SMS sent successfully to ${LogSanitizer.maskPhoneNumber(formattedPhone)}`,
      );
      // ✅ SAFE: Sanitize response before logging
      this.logger.log('Response:', LogSanitizer.sanitize(smsResponse));

      return true;
    } catch (error: unknown) {
      // ✅ SAFE: Mask phone in error log
      this.logger.error(
        `Failed to send SMS to ${LogSanitizer.maskPhoneNumber(phoneNumber)}`,
        error,
      );

      if (axios.isAxiosError(error)) {
        // ✅ SAFE: Sanitize API error
        this.logger.error(
          'API Error:',
          LogSanitizer.sanitize({
            status: error.response?.status,
            data: error.response?.data,
          }),
        );
      }

      if (error instanceof Error) {
        throw error;
      }

      throw new Error('Failed to send SMS due to unknown error');
    }
  }

  async sendOtpSms(phoneNumber: string, otpCode: string): Promise<boolean> {
    const message = `Koodhkaaga xaqiijinta waa ${otpCode}. Fadlan ha la wadaagin cidna. Wuu dhacayaa 10 daqiiqo gudahood.`;

    // ✅ SAFE: Log without OTP code
    this.logger.log(
      `Sending OTP SMS to ${LogSanitizer.maskPhoneNumber(phoneNumber)}`,
    );

    return this.sendSms(phoneNumber, message);
  }
}
