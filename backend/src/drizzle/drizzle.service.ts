import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
  Optional,
} from '@nestjs/common';
import { drizzle, NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool, PoolClient } from 'pg';
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
  keepAlive?: boolean;
  keepAliveInitialDelayMillis?: number;
  connectionRetryInterval?: number;
}

@Injectable()
export class DrizzleService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DrizzleService.name);
  private pool!: Pool;
  public db!: NodePgDatabase<typeof schema>;
  private config: Required<DrizzleConfig>;
  private isShuttingDown = false;
  private reconnectTimer: NodeJS.Timeout | null = null;
  private isReconnecting = false;
  private connectionMonitorInterval: NodeJS.Timeout | null = null;

  constructor(@Optional() config: DrizzleConfig = {}) {
    this.config = {
      max: 5, // Reduced for Neon free tier
      min: 1,
      idleTimeoutMillis: 20000,
      connectionTimeoutMillis: 15000,
      maxUses: 50,
      retryAttempts: 5,
      retryDelayMs: 1000,
      statementTimeout: 15000,
      queryTimeout: 15000,
      keepAlive: true,
      keepAliveInitialDelayMillis: 5000,
      connectionRetryInterval: 30000,
      ...config,
    };
  }

  async onModuleInit() {
    this.validateEnvironment();
    await this.initializePool();
    this.startConnectionMonitor();
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

      this.logger.log(
        `📍 Database: ${parsed.hostname}:${parsed.port || 5432}/${parsed.pathname.replace('/', '')}`,
      );
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
      this.pool = new Pool({
        connectionString,
        max: this.config.max,
        min: this.config.min,
        idleTimeoutMillis: this.config.idleTimeoutMillis,
        connectionTimeoutMillis: this.config.connectionTimeoutMillis,
        maxUses: this.config.maxUses,
        allowExitOnIdle: false,
        keepAlive: this.config.keepAlive,
        keepAliveInitialDelayMillis: this.config.keepAliveInitialDelayMillis,
        ssl: {
          rejectUnauthorized: false, // Neon requires SSL
        },
      });

      this.setupPoolEventHandlers();
      await this.testConnection();

      this.db = drizzle(this.pool, { schema });
      this.logger.log('✅ Neon PostgreSQL connected successfully');
    } catch (error) {
      this.logger.error(
        `Failed to initialize pool: ${(error as Error).message}`,
      );
      throw error;
    }
  }

  /**
   * Monitor connection health and reconnect if needed
   */
  private startConnectionMonitor(): void {
    this.connectionMonitorInterval = setInterval(async () => {
      if (this.isShuttingDown || this.isReconnecting) return;

      const isHealthy = await this.checkHealth();
      if (!isHealthy) {
        this.logger.warn(
          '⚠️ Database connection unhealthy, attempting reconnect...',
        );
        await this.reconnect();
      }
    }, this.config.connectionRetryInterval);
  }

  /**
   * Reconnect the pool
   */
  private async reconnect(): Promise<void> {
    if (this.isReconnecting || this.isShuttingDown) return;

    this.isReconnecting = true;
    this.logger.warn('🔄 Reconnecting to Neon PostgreSQL...');

    try {
      // Close old pool
      if (this.pool) {
        await this.pool.end().catch(() => {});
      }

      // Reinitialize pool
      await this.initializePool();
      this.logger.log('✅ Successfully reconnected to Neon PostgreSQL');
    } catch (error) {
      this.logger.error(`❌ Reconnection failed: ${(error as Error).message}`);

      // Schedule retry
      if (this.reconnectTimer) {
        clearTimeout(this.reconnectTimer);
      }

      this.reconnectTimer = setTimeout(() => {
        this.reconnect();
      }, this.config.retryDelayMs * 2);
    } finally {
      this.isReconnecting = false;
    }
  }

  private setupPoolEventHandlers(): void {
    this.pool.on('error', (err) => {
      this.logger.error(`Pool error: ${err.message}`);

      // Auto-reconnect on connection termination
      if (
        err.message.includes('Connection terminated') ||
        err.message.includes('Connection terminated unexpectedly') ||
        err.message.includes(
          'terminating connection due to administrator command',
        )
      ) {
        this.logger.warn(
          '🔄 Neon connection terminated, scheduling reconnect...',
        );
        setTimeout(() => {
          this.reconnect();
        }, 1000);
      }
    });

    this.pool.on('connect', (client) => {
      this.logger.debug('New client connected to pool');

      // Set statement timeout for each connection
      client
        .query(`SET statement_timeout = ${this.config.statementTimeout}`)
        .catch(() => {});
      client
        .query(
          `SET idle_in_transaction_session_timeout = ${this.config.queryTimeout}`,
        )
        .catch(() => {});
    });

    this.pool.on('remove', () => {
      this.logger.debug('Client removed from pool');
    });
  }

  private async testConnection(): Promise<void> {
    let client: PoolClient | undefined;
    try {
      client = await this.pool.connect();
      const result = await client.query(
        'SELECT version(), current_database(), current_user',
      );
      this.logger.log(`✅ Database connection test successful`);
      this.logger.log(`📊 PostgreSQL version: ${result.rows[0].version}`);
      this.logger.log(`📊 Database: ${result.rows[0].current_database}`);
      this.logger.log(`📊 User: ${result.rows[0].current_user}`);
    } catch (error) {
      const err = error as Error;
      this.logger.error(`❌ Failed to connect: ${err.message}`);

      if (err.message.includes('no pg_hba.conf entry')) {
        this.logger.error(
          '💡 Neon might have IP restrictions. Check your Neon dashboard for allowed IPs.',
        );
      }

      if (err.message.includes('password authentication failed')) {
        this.logger.error('💡 Check your DATABASE_URL password.');
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

          // Try to reconnect if needed
          if (attempt === Math.ceil(maxRetries / 2)) {
            await this.reconnect();
          }

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
      'terminating connection due to administrator command',
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
    let client: PoolClient | undefined;
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
    this.isShuttingDown = true;

    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
    }

    if (this.connectionMonitorInterval) {
      clearInterval(this.connectionMonitorInterval);
    }

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
