import { Injectable } from '@nestjs/common';
import { DrizzleService } from './drizzle/drizzle.service';
import { sql } from 'drizzle-orm';

@Injectable()
export class AppService {
  constructor(private readonly drizzle: DrizzleService) {}

  /**
   * Check database connectivity
   * @returns Object with status and timestamp
   */
  async checkDatabaseHealth(): Promise<{
    status: string;
    database: string;
    timestamp: string;
  }> {
    await this.drizzle.db.execute(sql`SELECT 1`);

    return {
      status: 'ok',
      database: 'connected',
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Get API information
   * @returns API metadata and available endpoints
   */
  getApiInfo() {
    return {
      message: 'Welcome to Ecommerce API Backend',
      version: '1.0.0',
      endpoints: {
        docs: '/api/docs',
        health: '/health',
      },
      timestamp: new Date().toISOString(),
    };
  }
}
