import { Module, forwardRef } from '@nestjs/common';
import { AffiliateService } from './affiliate.service';
import { AffiliateController } from './affiliate.controller';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ChatModule } from '../chat/chat.module';
import { AuthModule } from '../auth/auth.module';
import { PaymentModule } from 'src/payment/payment.module';

@Module({
  imports: [
    DrizzleModule,
    forwardRef(() => NotificationsModule),
    forwardRef(() => ChatModule),
    AuthModule,
    PaymentModule,
  ],
  controllers: [AffiliateController],
  providers: [AffiliateService],
  exports: [AffiliateService],
})
export class AffiliateModule {}
