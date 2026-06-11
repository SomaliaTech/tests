import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { drizzle, NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema';

export const DRIZZLE_DB = 'DRIZZLE_DB';

@Injectable()
export class DrizzleService implements OnModuleInit, OnModuleDestroy {
  private pool!: Pool;
  public db!: NodePgDatabase<typeof schema>;

  constructor() {}

  async onModuleInit() {
    await this.connectWithRetry();
  }

  private async connectWithRetry(retries = 5, delay = 2000): Promise<void> {
    for (let i = 0; i < retries; i++) {
      try {
        const connectionString = process.env.DATABASE_URL;
        if (!connectionString) throw new Error('DATABASE_URL not set');

        this.pool = new Pool({
          connectionString,
          ssl: { rejectUnauthorized: false },
          max: 20,
          idleTimeoutMillis: 30000,
          connectionTimeoutMillis: 10000,
          keepAlive: true,
        });

        // Test connection
        await this.pool.query('SELECT 1');
        this.db = drizzle(this.pool, { schema });
        console.log('✅ Database connected successfully');
        return;
      } catch (error) {
        console.error(
          `Connection attempt ${i + 1} failed:`,
          (error as Error).message,
        );
        if (i === retries - 1) throw error;
        await this.delay(delay);
      }
    }
  }

  private delay(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  async onModuleDestroy() {
    if (this.pool) await this.pool.end();
  }
}
