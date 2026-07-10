import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

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
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),

    DrizzleModule,
    // CloudflareModule,
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
    ChatModule,
    FaqModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
