// src/orders/orders.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ChatModule } from '../chat/chat.module';
import { PaymentModule } from '../payment/payment.module';
import { AffiliateModule } from '../affiliate/affiliate.module';

@Module({
  imports: [
    DrizzleModule,
    forwardRef(() => NotificationsModule),
    forwardRef(() => ChatModule),
    forwardRef(() => PaymentModule), // 👈 wrap
    forwardRef(() => AffiliateModule), // 👈 wrap
  ],
  controllers: [OrdersController],
  providers: [OrdersService],
  exports: [OrdersService],
})
export class OrdersModule {}
