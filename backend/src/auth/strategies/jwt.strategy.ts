// src/auth/strategies/jwt.strategy.ts
import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { DrizzleService } from '../../drizzle/drizzle.service';
import { users } from '../../drizzle/schema';
import { eq } from 'drizzle-orm';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  private readonly logger = new Logger(JwtStrategy.name);

  constructor(
    private configService: ConfigService,
    private drizzle: DrizzleService,
  ) {
    const jwtSecret = configService.get<string>('JWT_SECRET');

    if (!jwtSecret) {
      throw new Error('JWT_SECRET is not configured in environment variables');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: jwtSecret,
    });
  }

  async validate(payload: any) {
    const userId = payload.sub || payload.userId;

    if (!userId) {
      throw new UnauthorizedException('Invalid token');
    }

    try {
      // ✅ Use withRetry method (correct name)
      const [user] = await this.drizzle.withRetry(() =>
        this.drizzle.db
          .select()
          .from(users)
          .where(eq(users.id, userId))
          .limit(1),
      );

      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      if (!user.isActive) {
        throw new UnauthorizedException('Account is deactivated');
      }

      // ✅ Return user with FRESH admin status from database
      return {
        userId: user.id,
        sub: user.id,
        phoneNumber: user.phoneNumber,
        isAdmin: user.isAdmin === true,
        isSuperAdmin: user.isSuperAdmin === true,
      };
    } catch (error) {
      // ✅ If it's an UnauthorizedException, rethrow it
      if (error instanceof UnauthorizedException) {
        throw error;
      }

      // ✅ For database errors, log and use token payload as fallback
      this.logger.error(
        `Database error during JWT validation: ${error.message}`,
      );

      // Return user info from JWT payload as fallback (allows app to work during DB issues)
      this.logger.warn(
        '⚠️ Using JWT payload as fallback due to database error',
      );

      return {
        userId: userId,
        sub: userId,
        phoneNumber: payload.phoneNumber || '',
        isAdmin: payload.isAdmin === true,
        isSuperAdmin: payload.isSuperAdmin === true,
      };
    }
  }
}
