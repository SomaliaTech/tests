// src/app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler'; // Keep module for specific guards
// ❌ REMOVED: ThrottlerGuard from imports (no longer global)

import { ProductsModule } from './products/products.module';
import { CategoriesModule } from './categories/categories.module';
import { AuthModule } from './auth/auth.module';
import { MarketsModule } from './markets/markets.module';
import { OrdersModule } from './orders/orders.module';
import { DrizzleModule } from './drizzle/drizzle.module';
import { AppController } from './app.controller';
import { AdminModule } from './admin/admin.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { AppService } from './app.service';
import { SupabaseModule } from './supabase/supabase.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ChatModule } from './chat/chat.module';
import { FaqModule } from './faq/faq.module';
import { PermissionGuard } from './auth/guards/permission.guard';
import { PaymentModule } from './payment/payment.module';
import { BannersModule } from './banners/banners.module';
import { RedisModule } from './redis/redis.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),

    // ✅ KEEP ThrottlerModule so @Throttle() decorators in AuthController still work
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        { name: 'default', ttl: 60000, limit: 100 },
        { name: 'auth', ttl: 60000, limit: 20 },
        { name: 'otp', ttl: 60000, limit: 5 },
        { name: 'payment', ttl: 60000, limit: 10 },
      ],
    }),

    RedisModule,
    DrizzleModule,
    SupabaseModule,
    CategoriesModule,
    ProductsModule,
    AuthModule,
    AdminModule,
    ChatModule,
    MarketsModule,
    OrdersModule,
    DashboardModule,
    NotificationsModule,
    FaqModule,
    PaymentModule,
    BannersModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    PermissionGuard,
    // ❌ CRITICAL FIX: REMOVED ThrottlerGuard from APP_GUARD
    // This ensures logged-in users are NEVER rate limited globally.
  ],
})
export class AppModule {}
