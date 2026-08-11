// src/payment/waafipay.service.ts
import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

export interface WaafiPayConfig {
  merchantUId: string;
  apiUId: string;
  apiKey: string;
  baseUrl: string;
}

export interface PaymentRequest {
  amount: number;
  phoneNumber: string;
  orderId: string;
  description: string;
  referenceId: string;
}

export interface PaymentResponse {
  success: boolean;
  message: string;
  transactionId?: string;
  referenceId?: string;
  state?: string;
  responseCode?: string;
}

@Injectable()
export class WaafiPayService {
  private readonly logger = new Logger(WaafiPayService.name);
  private readonly config: WaafiPayConfig;

  constructor(private configService: ConfigService) {
    // ✅ Fix: Use fallback values with type assertions
    this.config = {
      merchantUId: this.configService.get('WAAFI_MERCHANT_UID') || '',
      apiUId: this.configService.get('WAAFI_API_UID') || '',
      apiKey: this.configService.get('WAAFI_API_KEY') || '',
      baseUrl:
        this.configService.get('WAAFI_BASE_URL') || 'https://api.waafipay.net',
    };

    if (
      !this.config.merchantUId ||
      !this.config.apiUId ||
      !this.config.apiKey
    ) {
      this.logger.warn('⚠️ WaafiPay credentials not fully configured');
    }
  }

  /**
   * Initiate a payment request to WaafiPay
   */
  async initiatePayment(data: PaymentRequest): Promise<PaymentResponse> {
    try {
      this.logger.log(`Initiating payment for order: ${data.orderId}`);

      const isMockMode = this.configService.get('WAAFI_MOCK_MODE') === 'true';

      if (isMockMode) {
        this.logger.warn('⚠️ MOCK MODE - Simulating successful payment');
        return {
          success: true,
          message: 'Payment simulated successfully (MOCK)',
          transactionId: `MOCK-TXN-${Date.now()}`,
          referenceId: data.referenceId,
          state: 'SUCCESS',
          responseCode: '2001',
        };
      }

      const requestBody = {
        schemaVersion: '1.0',
        requestId: data.referenceId,
        timestamp: new Date().toISOString(),
        channelName: 'WEB',
        serviceName: 'API_PURCHASE',
        serviceParams: {
          merchantUid: this.config.merchantUId, // ✅ Lowercase 'i' in Uid
          apiUserId: this.config.apiUId,
          apiKey: this.config.apiKey,
          paymentMethod: 'MWALLET_ACCOUNT',
          payerInfo: {
            accountNo: this.formatPhoneNumber(data.phoneNumber),
          },
          transactionInfo: {
            referenceId: data.referenceId,
            invoiceId: data.orderId,
            amount: data.amount,
            currency: 'USD',
            description: data.description,
          },
        },
      };
      this.logger.debug(`WaafiPay Request: ${JSON.stringify(requestBody)}`);

      const response = await axios.post(
        `${this.config.baseUrl}/asm`,
        requestBody,
        {
          headers: {
            'Content-Type': 'application/json',
          },
          timeout: 30000,
        },
      );

      this.logger.debug(`WaafiPay Response: ${JSON.stringify(response.data)}`);

      return this.parseResponse(response.data);
    } catch (error) {
      this.logger.error(`WaafiPay Payment Error: ${error.message}`);

      if (error.response) {
        this.logger.error(
          `Response data: ${JSON.stringify(error.response.data)}`,
        );
      }

      return {
        success: false,
        message:
          error.response?.data?.errorMsg || 'Payment failed. Please try again.',
      };
    }
  }

  /**
   * Check payment status
   */
  async checkPaymentStatus(referenceId: string): Promise<PaymentResponse> {
    try {
      const requestBody = {
        schemaVersion: '1.0',
        requestId: `STATUS-${Date.now()}`,
        timestamp: new Date().toISOString(),
        channelName: 'WEB',
        serviceName: 'API_CHECK_STATUS',
        serviceParams: {
          merchantUId: this.config.merchantUId,
          apiUserId: this.config.apiUId,
          apiKey: this.config.apiKey,
          referenceId: referenceId,
        },
      };

      const response = await axios.post(
        `${this.config.baseUrl}/asm`,
        requestBody,
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 15000,
        },
      );

      return this.parseResponse(response.data);
    } catch (error) {
      this.logger.error(`Status check error: ${error.message}`);
      return {
        success: false,
        message: 'Failed to check payment status.',
      };
    }
  }

  /**
   * Parse WaafiPay API response
   */
  private parseResponse(data: any): PaymentResponse {
    const params = data?.serviceParams || data?.params || {};
    const responseCode = params?.responseCode || data?.responseCode || '';
    const description = params?.responseMsg || data?.responseMsg || '';

    const isSuccess =
      responseCode === '2001' || description.includes('Success');

    return {
      success: isSuccess,
      message: description || 'Unknown response',
      transactionId: params?.transactionId || data?.transactionId,
      referenceId: params?.referenceId || data?.referenceId,
      state: params?.state || data?.state,
      responseCode: responseCode,
    };
  }

  /**
   * Format phone number for WaafiPay (remove +252, keep 9 digits)
   */
  formatPhoneNumber(phone: string): string {
    // ✅ Made public for use in orders service
    let cleaned = phone.replace(/\D/g, '');

    if (cleaned.startsWith('252')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.length !== 9) {
      throw new BadRequestException('Invalid phone number format');
    }

    return cleaned;
  }

  /**
   * Generate unique reference ID
   */
  generateReferenceId(orderId: string): string {
    return `PAY-${orderId.substring(0, 8)}-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
  }
}
