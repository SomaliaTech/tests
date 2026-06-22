import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { DrizzleModule } from '../drizzle/drizzle.module'; // Adjust path to your DrizzleModule

@Module({
  imports: [DrizzleModule],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
