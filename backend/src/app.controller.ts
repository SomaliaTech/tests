import { Controller, Get } from '@nestjs/common';
import { DrizzleService } from './drizzle/drizzle.service';
import { sql } from 'drizzle-orm';

@Controller()
export class AppController {
  constructor(private drizzle: DrizzleService) {}

  @Get('health')
  async healthCheck() {
    try {
      const result = await this.drizzle.db.execute(sql`SELECT 1 as connected`);
      return { status: 'ok', database: 'connected', result };
    } catch (error) {
      return { status: 'error', message: error.message };
    }
  }
}
