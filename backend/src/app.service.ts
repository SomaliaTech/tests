import { Controller, Get } from '@nestjs/common';
import { DrizzleService } from './drizzle/drizzle.service';
import { sql } from 'drizzle-orm';

@Controller()
export class AppController {
  constructor(private drizzle: DrizzleService) {}

  @Get('health')
  async healthCheck() {
    try {
      await this.drizzle.db.execute(sql`SELECT 1`);
      return {
        status: 'ok',
        database: 'connected',
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      return {
        status: 'error',
        message: error.message,
        timestamp: new Date().toISOString(),
      };
    }
  }
}
