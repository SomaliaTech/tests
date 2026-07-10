import { Module, forwardRef } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { ChatModule } from '../chat/chat.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    DrizzleModule,
    forwardRef(() => ChatModule),
    forwardRef(() => NotificationsModule),
  ],
  controllers: [OrdersController],
  providers: [OrdersService],
  exports: [OrdersService],
})
export class OrdersModule {}
