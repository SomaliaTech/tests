import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema';

// 👇 MAGIC FIX: This forces TypeScript to correctly infer the schema with all relations 👇
const _initDb = () => drizzle({} as any, { schema });
export type Database = ReturnType<typeof _initDb>;

@Injectable()
export class DrizzleService implements OnModuleInit, OnModuleDestroy {
  private pool!: Pool;

  // 👇 USE THE INFERRED DATABASE TYPE 👇
  public db!: Database;

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
          connectionTimeoutMillis: 10000,
          keepAlive: true,
        });

        // 👇 CRITICAL FIX: Prevents Node.js from crashing when Supabase drops idle connections 👇
        this.pool.on('error', (err) => {
          console.error(
            '⚠️ Unexpected error on idle PostgreSQL client:',
            err.message,
          );
          // We just log it. Do not throw, or the app will crash.
        });

        // Test connection immediately
        await this.pool.query('SELECT 1');

        // Initialize Drizzle with the schema and cast to our inferred type
        this.db = drizzle(this.pool, { schema }) as Database;

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
