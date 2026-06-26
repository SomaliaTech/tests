import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { drizzle, NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema';

@Injectable()
export class DrizzleService implements OnModuleInit, OnModuleDestroy {
  private pool!: Pool;
  public db!: NodePgDatabase<typeof schema>;

  async onModuleInit() {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error('DATABASE_URL is not defined in environment variables');
    }

    console.log('🔌 Connecting to Supabase PostgreSQL...');

    this.pool = new Pool({
      connectionString,
      ssl: { rejectUnauthorized: false },

      // ✅ Supabase-optimized settings
      max: 3, // Supabase free tier: keep low (3-5)
      min: 1, // Keep 1 connection alive
      idleTimeoutMillis: 10000, // Close idle after 10s (Supabase kills idle anyway)
      connectionTimeoutMillis: 15000, // Wait 15s max for connection
      keepAlive: true, // TCP keepalive
      keepAliveInitialDelayMillis: 5000,

      // ✅ Critical: These prevent hanging connections
      statement_timeout: 10000, // 10s query timeout
      query_timeout: 10000, // 10s query timeout
      idle_in_transaction_session_timeout: 10000,

      // ✅ Let connections go (don't hold them)
      allowExitOnIdle: true,
      maxUses: 100, // Recycle connections after 100 uses
    });

    // Handle pool events silently (Supabase drops connections frequently)
    this.pool.on('error', (err) => {
      // Don't crash - Supabase connections drop often
      if (!err.message.includes('Connection terminated')) {
        console.error('❌ Pool error:', err.message);
      }
    });

    this.pool.on('connect', () => {
      // Silent - too noisy otherwise
    });

    this.pool.on('remove', () => {
      // Silent - Supabase removes idle connections normally
    });

    // Test connection
    try {
      await this.pool.query('SELECT 1');
      console.log('✅ Supabase PostgreSQL connected successfully');
    } catch (error) {
      console.error(
        '❌ Failed to connect to Supabase:',
        (error as Error).message,
      );
      throw error;
    }

    this.db = drizzle(this.pool, { schema });
  }

  // ✅ Improved retry logic for connection errors only
  async withRetry<T>(
    queryFn: (db: NodePgDatabase<typeof schema>) => Promise<T>,
    maxRetries = 3,
    delayMs = 500,
  ): Promise<T> {
    let lastError: Error | null = null;

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await queryFn(this.db);
      } catch (error: any) {
        lastError = error;

        // Only retry on connection errors
        const isConnectionError =
          error.message?.includes('Connection terminated') ||
          error.message?.includes('timeout') ||
          error.message?.includes('Connection terminated unexpectedly');

        if (isConnectionError && attempt < maxRetries - 1) {
          console.warn(
            `⚠️ Connection error (attempt ${attempt + 1}/${maxRetries}), retrying...`,
          );
          await new Promise((resolve) =>
            setTimeout(resolve, delayMs * (attempt + 1)),
          );
        } else {
          // Don't retry - throw immediately
          throw error;
        }
      }
    }

    throw lastError || new Error('Query failed after all retries');
  }

  async onModuleDestroy() {
    if (this.pool) {
      try {
        await this.pool.end();
        console.log('💤 Supabase pool closed');
      } catch (error) {
        // Silently close
      }
    }
  }
}
