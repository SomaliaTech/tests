// src/redis/redis.module.ts
import { Module, Global, Logger } from '@nestjs/common';
import { Redis } from '@upstash/redis';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [
    {
      provide: 'REDIS_CLIENT',
      useFactory: async (config: ConfigService) => {
        const logger = new Logger('RedisModule');
        const redisUrl = config.get<string>('UPSTASH_REDIS_URL');

        if (!redisUrl) {
          logger.warn(
            '⚠️ UPSTASH_REDIS_URL not set, running without Redis cache',
          );
          return createMockRedisClient();
        }

        try {
          // Parse the Upstash URL: rediss://default:TOKEN@HOST:PORT
          const parsedUrl = new URL(redisUrl);
          const token = parsedUrl.password || '';
          const restUrl = `https://${parsedUrl.hostname}`;

          logger.log(
            `🔗 Connecting to Upstash Redis at: ${parsedUrl.hostname}`,
          );

          // Both url and token are required
          const redis = new Redis({
            url: restUrl,
            token: token,
          });

          // Test connection
          const pingResult = await redis.ping();
          logger.log(`✅ Redis connected successfully: ${pingResult}`);

          return redis;
        } catch (error) {
          logger.error(`❌ Redis connection failed: ${error.message}`);
          logger.warn(
            '⚠️ Running without Redis cache - performance will be degraded',
          );
          return createMockRedisClient();
        }
      },
      inject: [ConfigService],
    },
  ],
  exports: ['REDIS_CLIENT'],
})
export class RedisModule {}

function createMockRedisClient(): Redis {
  const logger = new Logger('MockRedis');

  return {
    get: async () => null,
    set: async () => 'OK',
    del: async () => 1,
    incr: async () => 1,
    decr: async () => 0,
    decrby: async () => 0,
    pipeline: () => ({
      incr: () => {},
      exec: async () => [],
    }),
    sadd: async () => 1,
    srem: async () => 1,
    sismember: async () => 0,
    smembers: async () => [],
    scard: async () => 0,
    expire: async () => 1,
  } as unknown as Redis;
}
