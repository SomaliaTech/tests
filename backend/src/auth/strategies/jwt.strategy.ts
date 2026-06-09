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

  async validate(payload: any) {
    const [user] = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, payload.sub));

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    return {
      userId: user.id,
      phoneNumber: user.phoneNumber,
      isVerified: user.isVerified,
    };
  }
}
