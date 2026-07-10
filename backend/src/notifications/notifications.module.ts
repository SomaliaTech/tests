import { Module, forwardRef } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { ChatModule } from '../chat/chat.module';
import { FirebaseModule } from '../firebase/firebase.module';

@Module({
  imports: [DrizzleModule, forwardRef(() => ChatModule), FirebaseModule],
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService], // ✅ Must export
})
export class NotificationsModule {}
