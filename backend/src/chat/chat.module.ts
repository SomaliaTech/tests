import { Module, forwardRef } from '@nestjs/common';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { ChatController } from './chat.controller';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { FirebaseModule } from '../firebase/firebase.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AdminModule } from '../admin/admin.module';
import { SupabaseModule } from 'src/supabase/supabase.module';

@Module({
  imports: [
    DrizzleModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        secret: config.get('JWT_SECRET'),
        signOptions: { expiresIn: '7d' },
      }),
      inject: [ConfigService],
    }),
    SupabaseModule,
    FirebaseModule,
    forwardRef(() => AdminModule),
    forwardRef(() => NotificationsModule),
  ],
  controllers: [ChatController],
  providers: [ChatService, ChatGateway],
  exports: [ChatService, ChatGateway, JwtModule],
})
export class ChatModule {}
