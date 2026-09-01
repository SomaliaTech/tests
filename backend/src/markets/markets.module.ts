// src/markets/markets.module.ts
import { Module } from '@nestjs/common';
import { MarketsController } from './markets.controller';
import { MarketsService } from './markets.service';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [DrizzleModule, ThrottlerModule],
  controllers: [MarketsController],
  providers: [MarketsService],
  exports: [MarketsService], // ✅ Export if other modules need it
})
export class MarketsModule {}
