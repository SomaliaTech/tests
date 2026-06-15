import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { drizzle, NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema';

@Injectable()
export class DrizzleService implements OnModuleInit, OnModuleDestroy {
  private pool!: Pool;
  public db!: NodePgDatabase<typeof schema>;

  async onModuleInit() {
    await this.connectWithRetry();
  }

  private async connectWithRetry(retries = 5, delayMs = 2000): Promise<void> {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error('DATABASE_URL is not defined in environment variables');
    }

    for (let i = 0; i < retries; i++) {
      try {
        this.pool = new Pool({
          connectionString,
          ssl: { rejectUnauthorized: false },
          max: 20,
          idleTimeoutMillis: 30000,
          connectionTimeoutMillis: 10000, // Kept at 10s to give Supabase room to wake up if cold
          keepAlive: true, // CRITICAL: Prevents premature connection termination
        });

        // Test connection immediately
        await this.pool.query('SELECT 1');

        this.db = drizzle(this.pool, { schema });
        console.log('✅ PostgreSQL connected successfully');
        return;
      } catch (error) {
        console.error(
          `❌ Connection attempt ${i + 1} failed:`,
          (error as Error).message,
        );

        // Clean up failed pool before retrying
        if (this.pool) {
          await this.pool.end().catch(() => {});
        }

        if (i === retries - 1) throw error;
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }
  }

  async onModuleDestroy() {
    if (this.pool) {
      await this.pool.end();
      console.log('💤 Database pool closed');
    }
  }
}
