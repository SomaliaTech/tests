// src/payment/payment.module.ts
import { Module } from '@nestjs/common';
import { PaymentController } from './payment.controller';
import { WaafiPayService } from './waafipay.service';
import { OrdersModule } from '../orders/orders.module';

@Module({
  imports: [OrdersModule],
  controllers: [PaymentController],
  providers: [WaafiPayService],
  exports: [WaafiPayService],
})
export class PaymentModule {}
