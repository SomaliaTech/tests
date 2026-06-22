import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { DrizzleService } from '../../drizzle/drizzle.service';
import { users } from '../../drizzle/schema';
import { eq } from 'drizzle-orm';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private drizzle: DrizzleService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get('JWT_SECRET') || 'your-secret-key',
    });
  }

  async validate(payload: { sub: string; phoneNumber: string }) {
    try {
      console.log(`🔍 Validating user: ${payload.sub}`);

      const result = await this.drizzle.db
        .select()
        .from(users)
        .where(eq(users.id, payload.sub))
        .limit(1);

      const user = result[0];

      if (!user) {
        console.log(`❌ User not found: ${payload.sub}`);
        throw new UnauthorizedException('User not found');
      }

      console.log(`✅ User validated: ${user.id}`);

      return {
        userId: user.id,
        phoneNumber: user.phoneNumber,
        isVerified: user.isVerified,
        isAdmin: user.isAdmin || false,
      };
    } catch (error: any) {
      console.error(`❌ JWT validation error: ${error.message}`);
      throw new UnauthorizedException('Invalid token or user not found');
    }
  }
}
