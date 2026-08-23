// src/common/guards/ip-rate-limit.guard.ts
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  Inject,
} from '@nestjs/common';
import { Redis } from '@upstash/redis';

@Injectable()
export class IpRateLimitGuard implements CanActivate {
  constructor(@Inject('REDIS_CLIENT') private readonly redis: Redis) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const ip = request.ip || request.connection?.remoteAddress || 'unknown';
    const route = request.route?.path || request.url;
    const key = `rate_limit:${ip}:${route}`;

    const current = await this.redis.incr(key);

    if (current === 1) {
      // Set expiry on the very first request in this window
      await this.redis.expire(key, 60); // 60 seconds window
    }

    if (current > 100) {
      // Adjust this limit per route as needed
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          message: 'Too many requests. Please try again later.',
          retryAfter: 60,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    return true;
  }
}
