import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
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

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000, // 1 minute in milliseconds
        limit: 10, // 10 requests per minute
      },
    ]),
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
    PermissionGuard, // ✅ Guard registered as a provider
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard, // ✅ Global rate limiting
    },
  ],
})
export class AppModule {}
