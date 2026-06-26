import { Module, forwardRef } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { CloudflareModule } from '../cloudfare/cloudflare.module';
import { ChatModule } from '../chat/chat.module'; // ✅ Import ChatModule

@Module({
  imports: [
    DrizzleModule,
    CloudflareModule,
    forwardRef(() => ChatModule), // ✅ Use forwardRef to avoid circular dependency
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
