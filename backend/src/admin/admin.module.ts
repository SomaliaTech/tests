import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { CloudflareModule } from '../cloudfare/cloudflare.module';

@Module({
  imports: [DrizzleModule, CloudflareModule],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
