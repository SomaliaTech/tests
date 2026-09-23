// src/support/support.module.ts
import { Module } from '@nestjs/common';
import { DrizzleModule } from '../drizzle/drizzle.module';
import { SupportService } from './support.service';
import { SupportController } from './support.controller';

@Module({
  imports: [DrizzleModule],
  controllers: [SupportController],
  providers: [SupportService],
  exports: [SupportService],
})
export class SupportModule {}
