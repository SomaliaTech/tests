import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

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

    // ✅ GLOBAL RATE LIMIT CONFIGURATION
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        {
          name: 'default',
          ttl: 60000, // 1 minute
          limit: 500, // ✅ INCREASED to 500 to prevent 429 on app startup
        },
        {
          name: 'auth',
          ttl: 60000,
          limit: 20,
        },
        {
          name: 'otp',
          ttl: 60000,
          limit: 5,
        },
        {
          name: 'payment',
          ttl: 60000,
          limit: 10,
        },
      ],
    }),

    // Feature Modules
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
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard, // ✅ Applies the 500 req/min limit globally
    },
  ],
})
export class AppModule {}
