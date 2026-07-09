import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
  Optional,
} from '@nestjs/common';
import { drizzle, NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema';

interface DrizzleConfig {
  max?: number;
  min?: number;
  idleTimeoutMillis?: number;
  connectionTimeoutMillis?: number;
  maxUses?: number;
  retryAttempts?: number;
  retryDelayMs?: number;
  statementTimeout?: number;
  queryTimeout?: number;
}

@Injectable()
export class DrizzleService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DrizzleService.name);
  private pool!: Pool;
  public db!: NodePgDatabase<typeof schema>;
  private config: Required<DrizzleConfig>;

  constructor(@Optional() config: DrizzleConfig = {}) {
    this.config = {
      max: 10, // Neon can handle more connections
      min: 2,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
      maxUses: 100,
      retryAttempts: 3,
      retryDelayMs: 500,
      statementTimeout: 10000,
      queryTimeout: 10000,
      ...config,
    };
  }

  async onModuleInit() {
    this.validateEnvironment();
    await this.initializePool();
  }

  private validateEnvironment(): void {
    const url = process.env.DATABASE_URL;
    if (!url) {
      throw new Error('DATABASE_URL is not defined in environment variables');
    }

    try {
      const parsed = new URL(url);
      
      if (!parsed.username) {
        throw new Error('DATABASE_URL missing username');
      }
      
      if (!parsed.password) {
        throw new Error('DATABASE_URL missing password');
      }

      this.logger.log(`📍 Database: ${parsed.hostname}:${parsed.port || 5432}/${parsed.pathname.replace('/', '')}`);
      this.logger.log(`👤 User: ${parsed.username}`);
      
    } catch (error) {
      if (error instanceof Error) {
        throw new Error(`Invalid DATABASE_URL: ${error.message}`);
      }
      throw new Error('Invalid DATABASE_URL');
    }
  }

  private async initializePool(): Promise<void> {
    const connectionString = process.env.DATABASE_URL!;

    this.logger.log('🔌 Connecting to Neon PostgreSQL...');

    try {
      // Neon uses sslmode=require in the connection string
      // We don't need to add SSL config separately
      this.pool = new Pool({
        connectionString,
        // Neon optimized settings
        max: this.config.max,
        min: this.config.min,
        idleTimeoutMillis: this.config.idleTimeoutMillis,
        connectionTimeoutMillis: this.config.connectionTimeoutMillis,
        maxUses: this.config.maxUses,
        allowExitOnIdle: true,
        // Neon specific: Keep connections alive
        keepAlive: true,
        keepAliveInitialDelayMillis: 10000,
      });

      this.setupPoolEventHandlers();
      await this.testConnection();

      this.db = drizzle(this.pool, { schema });
      this.logger.log('✅ Neon PostgreSQL connected successfully');
    } catch (error) {
      this.logger.error(`Failed to initialize pool: ${(error as Error).message}`);
      throw error;
    }
  }

  private setupPoolEventHandlers(): void {
    this.pool.on('error', (err) => {
      // Neon connections are stable, but handle errors gracefully
      this.logger.error(`Pool error: ${err.message}`, err.stack);
    });

    if (process.env.NODE_ENV !== 'production') {
      this.pool.on('connect', () => {
        this.logger.debug('New client connected to pool');
      });
      
      this.pool.on('acquire', () => {
        this.logger.debug('Client acquired from pool');
      });
      
      this.pool.on('remove', () => {
        this.logger.debug('Client removed from pool');
      });
    }
  }

  private async testConnection(): Promise<void> {
    let client;
    try {
      client = await this.pool.connect();
      const result = await client.query('SELECT version(), current_database(), current_user');
      this.logger.log(`✅ Database connection test successful`);
      this.logger.log(`📊 PostgreSQL version: ${result.rows[0].version}`);
      this.logger.log(`📊 Database: ${result.rows[0].current_database}`);
      this.logger.log(`📊 User: ${result.rows[0].current_user}`);
    } catch (error) {
      const err = error as Error;
      this.logger.error(`❌ Failed to connect: ${err.message}`);
      
      // Helpful hints for Neon
      if (err.message.includes('no pg_hba.conf entry')) {
        this.logger.error('💡 Neon might have IP restrictions. Check your Neon dashboard for allowed IPs.');
      }
      
      if (err.message.includes('password authentication failed')) {
        this.logger.error('💡 Check your DATABASE_URL password. Make sure it\'s correct.');
      }
      
      throw error;
    } finally {
      if (client) {
        client.release();
      }
    }
  }

  async withRetry<T>(
    queryFn: (db: NodePgDatabase<typeof schema>) => Promise<T>,
    maxRetries = this.config.retryAttempts,
  ): Promise<T> {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await queryFn(this.db);
      } catch (error: any) {
        const isConnectionError = this.isConnectionError(error);
        if (isConnectionError && attempt < maxRetries) {
          const delay = this.config.retryDelayMs * Math.pow(2, attempt - 1);
          this.logger.warn(
            `Connection error (${attempt}/${maxRetries}), retrying in ${delay}ms`,
          );
          await this.sleep(delay);
          continue;
        }
        throw error;
      }
    }
    throw new Error('Max retries exceeded');
  }

  private isConnectionError(error: any): boolean {
    const message = error.message || '';
    return [
      'Connection terminated',
      'timeout',
      'ECONNRESET',
      'ETIMEDOUT',
      'Connection terminated unexpectedly',
      'no pg_hba.conf entry',
    ].some((term) => message.includes(term));
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  async getPoolStats() {
    return {
      total: this.pool.totalCount,
      idle: this.pool.idleCount,
      waiting: this.pool.waitingCount,
      active: this.pool.totalCount - this.pool.idleCount,
    };
  }

  async checkHealth(): Promise<boolean> {
    let client;
    try {
      client = await this.pool.connect();
      await client.query('SELECT 1');
      return true;
    } catch {
      return false;
    } finally {
      if (client) {
        client.release();
      }
    }
  }

  async onModuleDestroy() {
    if (this.pool) {
      try {
        await this.pool.end();
        this.logger.log('💤 Neon pool closed');
      } catch (error) {
        this.logger.error('Error closing pool', error);
      }
    }
  }
}