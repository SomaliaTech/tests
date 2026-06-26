import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { DrizzleModule } from '../drizzle/drizzle.module';

@Module({
  imports: [DrizzleModule],
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService], // ✅ Must export this
})
export class NotificationsModule {}
