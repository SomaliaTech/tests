import {
  Injectable,
  UnauthorizedException,
  InternalServerErrorException,
} from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { DrizzleService } from '../../drizzle/drizzle.service';
import { users } from '../../drizzle/schema';
import { sql } from 'drizzle-orm';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private drizzle: DrizzleService,
  ) {
    const secret = configService.get('JWT_SECRET') || 'your-secret-key';
    console.log('🔑 JWT Secret configured:', secret ? '✅ Yes' : '❌ No');

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: { sub: string; phoneNumber: string }) {
    try {
      console.log(`🔍 Validating user: ${payload.sub}`);

      // ✅ Use a simpler select that handles missing columns gracefully
      const result = await this.drizzle.db.execute(sql`
        SELECT 
          id, 
          phone_number, 
          email, 
          name, 
          profile_image, 
          market_id, 
          is_verified, 
          otp_code, 
          otp_expires_at, 
          created_at, 
          updated_at, 
          is_admin,
          COALESCE(is_online, false) as is_online,
          last_seen
        FROM users 
        WHERE id = ${payload.sub}
        LIMIT 1
      `);

      const user = result.rows[0];

      if (!user) {
        console.log(`❌ User not found: ${payload.sub}`);
        throw new UnauthorizedException('User not found');
      }

      console.log(`✅ User validated: ${user.id}`);

      return {
        userId: user.id,
        phoneNumber: user.phone_number,
        isVerified: user.is_verified,
        isAdmin: user.is_admin || false,
        isOnline: user.is_online || false,
        lastSeen: user.last_seen,
      };
    } catch (error: any) {
      // 🔥 CRITICAL FIX: If the error is about missing columns,
      // catch it and return a fallback response
      if (
        error.message?.includes('column') &&
        error.message?.includes('does not exist')
      ) {
        console.warn('⚠️ Missing columns detected, trying fallback query...');

        try {
          // Fallback query without the new columns
          const fallbackResult = await this.drizzle.db.execute(sql`
            SELECT 
              id, 
              phone_number, 
              email, 
              name, 
              profile_image, 
              market_id, 
              is_verified, 
              otp_code, 
              otp_expires_at, 
              created_at, 
              updated_at, 
              is_admin
            FROM users 
            WHERE id = ${payload.sub}
            LIMIT 1
          `);

          const user = fallbackResult.rows[0];

          if (!user) {
            console.log(`❌ User not found: ${payload.sub}`);
            throw new UnauthorizedException('User not found');
          }

          console.log(`✅ User validated (fallback): ${user.id}`);

          return {
            userId: user.id,
            phoneNumber: user.phone_number,
            isVerified: user.is_verified,
            isAdmin: user.is_admin || false,
            isOnline: false,
            lastSeen: null,
          };
        } catch (fallbackError) {
          console.error('❌ Fallback query also failed:', fallbackError);
          throw new InternalServerErrorException(
            'Server error during authentication',
          );
        }
      }

      if (error instanceof UnauthorizedException) {
        throw error;
      }

      console.error(`❌ JWT validation DB error: ${error.message}`);
      throw new InternalServerErrorException(
        'Server error during authentication',
      );
    }
  }
}
