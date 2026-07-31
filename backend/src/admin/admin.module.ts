// src/admin/admin.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { CloudflareModule } from '../cloudfare/cloudflare.module';
import { ChatModule } from '../chat/chat.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PermissionGuard } from 'src/auth/guards/permission.guard';

@Module({
  imports: [
    DrizzleModule,
    CloudflareModule,
    forwardRef(() => ChatModule),
    forwardRef(() => NotificationsModule),
  ],
  controllers: [AdminController],
  providers: [
    AdminService,
    PermissionGuard, // ✅ Correct - in providers
  ],
  exports: [AdminService],
})
export class AdminModule {}
