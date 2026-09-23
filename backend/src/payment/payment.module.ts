// src/payment/payment.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { WaafiPayService } from './waafipay.service';
import { PaymentController } from './payment.controller';
import { OrdersModule } from '../orders/orders.module'; // 👈 direct import
import { DrizzleModule } from '../drizzle/drizzle.module';

@Module({
  imports: [
    DrizzleModule,
    forwardRef(() => OrdersModule), // 👈 wrap in forwardRef
  ],
  controllers: [PaymentController],
  providers: [WaafiPayService],
  exports: [WaafiPayService], // 👈 make sure this is exported
})
export class PaymentModule {}
