import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import * as crypto from 'crypto';

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

  constructor(private configService: ConfigService) {
    const username = this.configService.get<string>('HORMUUD_USERNAME');
    const password = this.configService.get<string>('HORMUUD_PASSWORD');
    const senderId = this.configService.get<string>('HORMUUD_SENDER_ID');

    this.logger.log('✅ Hormuud credentials configured');
    this.logger.log(`   Username: ${username ?? 'MISSING'}`);
    this.logger.log(`   Password: ${password ? '***HIDDEN***' : 'MISSING'}`);
    this.logger.log(`   Sender ID: ${senderId ?? 'MISSING'}`);
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
      return this.accessToken;
    } catch (error: unknown) {
      if (axios.isAxiosError(error)) {
        this.logger.error('Token API Error:', {
          status: error.response?.status,
          data: error.response?.data,
        });

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
      this.logger.error(`Failed to get Hormuud access token: ${errorMessage}`);
      throw new Error('Failed to authenticate with Hormuud SMS provider');
    }
  }

  async sendSms(phoneNumber: string, message: string): Promise<boolean> {
    try {
      const token = await this.getAccessToken();
      const formattedPhone = phoneNumber.replace('+', '');
      const senderId = this.configService.get<string>('HORMUUD_SENDER_ID');

      this.logger.log(
        `Sending SMS to ${formattedPhone} from ${senderId ?? 'Unknown'}`,
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
        this.logger.error(`SMS sending failed: ${description}`);

        if (description === 'Zero Balance!!') {
          throw new Error(
            'Hormuud SMS account has zero balance. Please add SMS credit.',
          );
        }

        throw new Error(`SMS sending failed: ${description}`);
      }

      this.logger.log(`✅ SMS sent successfully to ${formattedPhone}`);
      this.logger.log('Response:', JSON.stringify(smsResponse));
      return true;
    } catch (error: unknown) {
      this.logger.error(`Failed to send SMS to ${phoneNumber}`);

      if (axios.isAxiosError(error)) {
        this.logger.error('API Error:', {
          status: error.response?.status,
          data: error.response?.data,
        });
      }

      if (error instanceof Error) {
        throw error;
      }

      throw new Error('Failed to send SMS due to unknown error');
    }
  }

  async sendOtpSms(phoneNumber: string, otpCode: string): Promise<boolean> {
    const message = `Koodhkaaga xaqiijinta waa ${otpCode}. Fadlan ha la wadaagin cidna. Wuu dhacayaa 10 daqiiqo gudahood.`;
    return this.sendSms(phoneNumber, message);
  }
}
