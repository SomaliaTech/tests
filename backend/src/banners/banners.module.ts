import { forwardRef, Module } from '@nestjs/common';
import { BannersController } from './banners.controller';
import { BannersService } from './banners.service';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { SupabaseModule } from '../supabase/supabase.module';
import { NotificationsModule } from 'src/notifications/notifications.module';

@Module({
  imports: [
    DrizzleModule,
    SupabaseModule,
    forwardRef(() => NotificationsModule), // ✅ Use forwardRef to prevent circular dependency issues
  ],
  controllers: [BannersController],
  providers: [BannersService],
  exports: [BannersService],
})
export class BannersModule {}
