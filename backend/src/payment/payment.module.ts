// src/payment/payment.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { WaafiPayService } from './waafipay.service';
import { PaymentController } from './payment.controller';
import { PaymentWebhookController } from './payment-webhook.controller';
import { OrdersModule } from '../orders/orders.module';
import { DrizzleModule } from '../drizzle/drizzle.module';

@Module({
  imports: [DrizzleModule, forwardRef(() => OrdersModule)],
  controllers: [
    PaymentController,
    PaymentWebhookController, // ✅ Moved here
  ],
  providers: [WaafiPayService],
  exports: [WaafiPayService], // ✅ Removed duplicate
})
export class PaymentModule {}
