import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private configService: ConfigService) {
    const secret = configService.get('JWT_SECRET') || 'your-secret-key';
    console.log('🔑 JWT Secret configured:', secret ? '✅ Yes' : '❌ No');

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: any) {
    // ✅ Simplified: Just extract from payload without DB query
    return {
      userId: payload.sub,
      phoneNumber: payload.phoneNumber,
      isVerified: payload.isVerified ?? true,
      isAdmin: payload.isAdmin ?? false,
      isOnline: false,
      lastSeen: null,
    };
  }
}
