import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { PassportModule } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './strategies/jwt.strategy'; // Ensure this path matches your project
import { DrizzleModule } from '../drizzle/drizzle.module';
import { SupabaseModule } from '../supabase/supabase.module';
import { CloudflareModule } from '../cloudfare/cloudflare.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { HormuudModule } from '../hormuud/hormuud.module';
import { RedisModule } from '../redis/redis.module';

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: async (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: { expiresIn: '90d' }, // Matches your 90-day token generation
      }),
    }),
    DrizzleModule,
    SupabaseModule,
    CloudflareModule,
    NotificationsModule,
    HormuudModule,
    RedisModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService, JwtModule],
})
export class AuthModule {}
