// src/payment/waafipay.service.ts
import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosError } from 'axios';
import { LogSanitizer } from '../common/utils/log-sanitizer.util';

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
  paymentMethod?: string;
}

export interface PaymentResponse {
  success: boolean;
  message: string;
  transactionId?: string;
  referenceId?: string;
  state?: string;
  responseCode?: string;
}

interface WaafiPayApiResponse {
  serviceParams?: {
    responseCode?: string;
    responseMsg?: string;
    transactionId?: string;
    referenceId?: string;
    state?: string;
    params?: Record<string, unknown>;
  };
  params?: {
    responseCode?: string;
    responseMsg?: string;
    transactionId?: string;
    referenceId?: string;
    state?: string;
  };
  responseCode?: string;
  responseMsg?: string;
  transactionId?: string;
  referenceId?: string;
  state?: string;
}

@Injectable()
export class WaafiPayService {
  private readonly logger = new Logger(WaafiPayService.name);
  private readonly config: WaafiPayConfig;

  constructor(private configService: ConfigService) {
    this.config = {
      merchantUId: this.configService.get<string>('WAAFI_MERCHANT_UID') || '',
      apiUId: this.configService.get<string>('WAAFI_API_UID') || '',
      apiKey: this.configService.get<string>('WAAFI_API_KEY') || '',
      baseUrl:
        this.configService.get<string>('WAAFI_BASE_URL') ||
        'https://api.waafipay.net',
    };

    if (
      !this.config.merchantUId ||
      !this.config.apiUId ||
      !this.config.apiKey
    ) {
      this.logger.warn('⚠️ WaafiPay credentials not fully configured');
    } else {
      // ✅ SAFE: Log only masked credentials
      this.logger.log('✅ WaafiPay credentials configured');
      this.logger.log(
        `   Merchant UID: ${LogSanitizer.maskValue(this.config.merchantUId)}`,
      );
      this.logger.log(
        `   API UID: ${LogSanitizer.maskValue(this.config.apiUId)}`,
      );
      this.logger.log('   API Key: ***CONFIGURED***');
    }
  }

  private createSafeRequestBody(
    data: PaymentRequest,
    referenceId: string,
    orderId: string,
  ): any {
    const requestBody = {
      schemaVersion: '1.0',
      requestId: referenceId,
      timestamp: new Date().toISOString(),
      channelName: 'WEB',
      serviceName: 'API_PURCHASE',
      serviceParams: {
        merchantUid: this.config.merchantUId,
        apiUserId: this.config.apiUId,
        apiKey: this.config.apiKey,
        paymentMethod: 'MWALLET_ACCOUNT',
        payerInfo: {
          accountNo: this.formatPhoneNumber(data.phoneNumber),
        },
        transactionInfo: {
          referenceId: referenceId,
          invoiceId: orderId,
          amount: data.amount.toString(),
          currency: 'USD',
          description: data.description,
        },
      },
    };

    return requestBody;
  }

  async initiatePayment(data: PaymentRequest): Promise<PaymentResponse> {
    try {
      this.logger.log(`Initiating payment for order: ${data.orderId}`);

      const isMockMode =
        this.configService.get<string>('WAAFI_MOCK_MODE') === 'true';

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

      const waafiPaymentMethod = this.getWaafiPaymentMethod(data.paymentMethod);
      this.logger.debug(`Using payment method: ${waafiPaymentMethod}`);

      const requestBody = this.createSafeRequestBody(
        data,
        data.referenceId,
        data.orderId,
      );

      // ✅ SAFE: Log sanitized request body (mask API key and phone)
      const safeRequestBody = LogSanitizer.sanitize(requestBody);
      this.logger.debug(`WaafiPay Request: ${JSON.stringify(safeRequestBody)}`);

      const response = await axios.post<WaafiPayApiResponse>(
        `${this.config.baseUrl}/asm`,
        requestBody,
        {
          headers: {
            'Content-Type': 'application/json',
          },
          timeout: 30000,
        },
      );

      // ✅ SAFE: Log sanitized response
      const safeResponse = LogSanitizer.sanitize(response.data);
      this.logger.debug(`WaafiPay Response: ${JSON.stringify(safeResponse)}`);

      return this.parseResponse(response.data);
    } catch (error: unknown) {
      if (error instanceof Error) {
        // ✅ SAFE: Sanitize error message
        this.logger.error(
          `WaafiPay Payment Error: ${LogSanitizer.sanitizeString(error.message)}`,
        );
      }

      if (axios.isAxiosError(error)) {
        const axiosError = error as AxiosError<{
          responseMsg?: string;
          errorMsg?: string;
        }>;
        if (axiosError.response?.data) {
          // ✅ SAFE: Sanitize response data
          const safeErrorData = LogSanitizer.sanitize(axiosError.response.data);
          this.logger.error(`Response data: ${JSON.stringify(safeErrorData)}`);
          return {
            success: false,
            message:
              axiosError.response.data.responseMsg ||
              axiosError.response.data.errorMsg ||
              'Payment failed. Please try again.',
          };
        }
      }

      return {
        success: false,
        message: 'Payment failed. Please try again.',
      };
    }
  }

  async checkPaymentStatus(referenceId: string): Promise<PaymentResponse> {
    try {
      const requestBody = {
        schemaVersion: '1.0',
        requestId: `STATUS-${Date.now()}`,
        timestamp: new Date().toISOString(),
        channelName: 'WEB',
        serviceName: 'API_CHECK_STATUS',
        serviceParams: {
          merchantUid: this.config.merchantUId,
          apiUserId: this.config.apiUId,
          apiKey: this.config.apiKey,
          referenceId: referenceId,
        },
      };

      // ✅ SAFE: Log sanitized request body
      const safeRequestBody = LogSanitizer.sanitize(requestBody);
      this.logger.debug(
        `Status Check Request: ${JSON.stringify(safeRequestBody)}`,
      );

      const response = await axios.post<WaafiPayApiResponse>(
        `${this.config.baseUrl}/asm`,
        requestBody,
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 15000,
        },
      );

      // ✅ SAFE: Log sanitized response
      const safeResponse = LogSanitizer.sanitize(response.data);
      this.logger.debug(
        `Status Check Response: ${JSON.stringify(safeResponse)}`,
      );

      return this.parseResponse(response.data);
    } catch (error: unknown) {
      if (error instanceof Error) {
        this.logger.error(
          `Status check error: ${LogSanitizer.sanitizeString(error.message)}`,
        );
      }
      return {
        success: false,
        message: 'Failed to check payment status.',
      };
    }
  }

  private parseResponse(data: WaafiPayApiResponse): PaymentResponse {
    const params = data?.serviceParams || data?.params || {};
    const responseCode = params?.responseCode || data?.responseCode || '';
    const description = params?.responseMsg || data?.responseMsg || '';

    const isSuccess =
      responseCode === '2001' || description.toLowerCase().includes('success');

    let friendlyMessage = description || 'Unknown response';

    if (responseCode === '5310' || description.includes('REJECTED')) {
      friendlyMessage = 'Payment was cancelled or rejected. Please try again.';
    } else if (
      responseCode === '5010' ||
      description.includes('not authorized')
    ) {
      friendlyMessage = 'Payment service is currently unavailable.';
    } else if (
      responseCode === '5005' ||
      description.includes('Insufficient')
    ) {
      friendlyMessage = 'Insufficient funds in mobile wallet.';
    }

    return {
      success: isSuccess,
      message: friendlyMessage,
      transactionId: params?.transactionId || data?.transactionId,
      referenceId: params?.referenceId || data?.referenceId,
      state: params?.state || data?.state,
      responseCode: responseCode,
    };
  }

  private getWaafiPaymentMethod(method: string | undefined): string {
    if (!method) return 'EVC_PLUS';

    const upper = method.toUpperCase().replace(/\s+/g, '_');

    if (upper.includes('EVC') || upper.includes('HORMUUD')) return 'EVC_PLUS';
    if (upper.includes('ZAAD') || upper.includes('TELESOM')) return 'ZAAD';
    if (upper.includes('DAHAB') || upper.includes('EDAHAB')) return 'E_DAHAB';
    if (upper.includes('SAHAL') || upper.includes('GOLIS')) return 'SAHAL';
    if (upper.includes('WAAFI')) return 'MWALLET_ACCOUNT';
    if (upper.includes('PREMIER')) return 'PREMIER_WALLET';

    const validCodes = [
      'EVC_PLUS',
      'ZAAD',
      'E_DAHAB',
      'SAHAL',
      'MWALLET_ACCOUNT',
      'PREMIER_WALLET',
    ];
    if (validCodes.includes(upper)) return upper;

    return 'EVC_PLUS';
  }

  formatPhoneNumber(phone: string): string {
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

  generateReferenceId(orderId: string): string {
    return `PAY-${orderId.substring(0, 8)}-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
  }
}
