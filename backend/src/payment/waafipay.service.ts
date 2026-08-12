import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosError } from 'axios';

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
    }
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

      //       {
      // 	"schemaVersion": "1.0",
      //   "requestId": "{{$guid}}",
      //     "timestamp": "{{$timestamp}}",
      // 	"channelName": "WEB",
      // 	"serviceName": "API_PURCHASE",
      // 	"serviceParams": {
      //      "merchantUid": "M0914352",
      //         "apiUserId": "1009097",
      //         "apiKey": "API-CXV4bcVgLIQMEBrN0PWWN4c5LUla",
      // 	"paymentMethod": "MWALLET_ACCOUNT",
      // 	"payerInfo": {
      // 			 "accountNo": "252612883364"
      // 		},
      // 	"transactionInfo": {
      // 		"referenceId": "FR_{{$randomBankAccount}}",
      // 		"invoiceId": "FR_IN_{{$randomBankAccount}}",
      // 		"amount": "0.1",
      // 		"currency": "USD",
      // 		"description": "test direct purchase"
      // 		}
      // 	}
      // }
      const requestBody = {
        schemaVersion: '1.0',
        requestId: data.referenceId, // ✅ FIX: Use actual referenceId (Removed {{$guid}})
        timestamp: new Date().toISOString(), // ✅ FIX: Use actual time (Removed {{$timestamp}})
        channelName: 'WEB',
        serviceName: 'API_PURCHASE',
        serviceParams: {
          merchantUid: this.config.merchantUId,
          apiUserId: this.config.apiUId,
          apiKey: this.config.apiKey,
          paymentMethod: 'MWALLET_ACCOUNT', // ✅ FIX: Use the dynamic variable, NOT 'MWALLET_ACCOUNT'
          payerInfo: {
            accountNo: this.formatPhoneNumber(data.phoneNumber),
          },
          transactionInfo: {
            referenceId: data.referenceId,
            invoiceId: data.orderId,
            amount: data.amount.toString(),
            currency: 'USD',
            description: data.description,
          },
        },
      };

      this.logger.debug(`WaafiPay Request: ${JSON.stringify(requestBody)}`);

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

      this.logger.debug(`WaafiPay Response: ${JSON.stringify(response.data)}`);

      return this.parseResponse(response.data);
    } catch (error: unknown) {
      if (error instanceof Error) {
        this.logger.error(`WaafiPay Payment Error: ${error.message}`);
      }

      if (axios.isAxiosError(error)) {
        const axiosError = error as AxiosError<{
          responseMsg?: string;
          errorMsg?: string;
        }>;
        if (axiosError.response?.data) {
          this.logger.error(
            `Response data: ${JSON.stringify(axiosError.response.data)}`,
          );
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

      const response = await axios.post<WaafiPayApiResponse>(
        `${this.config.baseUrl}/asm`,
        requestBody,
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 15000,
        },
      );

      return this.parseResponse(response.data);
    } catch (error: unknown) {
      if (error instanceof Error) {
        this.logger.error(`Status check error: ${error.message}`);
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

    // ✅ Map WaafiPay codes to friendly messages
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
