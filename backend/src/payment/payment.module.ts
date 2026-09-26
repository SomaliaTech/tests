// src/payment/payment.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { WaafiPayService } from './waafipay.service';
import { PaymentController } from './payment.controller';
import { OrdersModule } from '../orders/orders.module';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { PaymentReconciliationService } from './payment-reconciliation.service';

@Module({
  imports: [DrizzleModule, forwardRef(() => OrdersModule)],
  controllers: [PaymentController],
  providers: [WaafiPayService, PaymentReconciliationService],
  exports: [WaafiPayService],
})
export class PaymentModule {}
