// src/auth/auth.service.ts
import {
  BadRequestException,
  Inject,
  Injectable,
  UnauthorizedException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Redis } from '@upstash/redis';
import { DrizzleService } from '../drizzle/drizzle.service';
import { CloudflareService } from 'src/cloudfare/cloudflare.service';
import { markets, users } from '../drizzle/schema';
import { eq } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { SupabaseService } from 'src/supabase/supabase.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OAuth2Client, TokenPayload } from 'google-auth-library';
import { HormuudService } from '../hormuud/hormuud.service';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { FacebookAuthDto } from './dto/facebook-auth.dto';
import { LogSanitizer } from '../common/utils/log-sanitizer.util';
import axios from 'axios';
import * as crypto from 'crypto';

interface User {
  id: string;
  phoneNumber: string;
  email: string | null;
  name: string | null;
  profileImage: string | null;
  marketId: string | null;
  isVerified: boolean | null;
  isAdmin: boolean | null;
  isSuperAdmin: boolean | null;
  otpCode: string | null;
  otpExpiresAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
  isOnline: boolean;
  lastSeen: Date | null;
}

interface UpdateUserData {
  name?: string;
  marketId?: string;
  phoneNumber?: string;
  profileImage?: string;
  isVerified?: boolean;
  isActive?: boolean;
  updatedAt: Date;
}

interface OtpCacheData {
  otpHash: string; // ✅ Store hash instead of plain OTP
  phoneNumber: string;
  attempts: number;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private googleClient: OAuth2Client;
  private readonly isProduction: boolean;
  private readonly GOOGLE_ISSUERS = [
    'https://accounts.google.com',
    'accounts.google.com',
  ];
  private readonly MAX_OTP_ATTEMPTS = 5;
  private readonly OTP_TTL_SECONDS = 600; // 10 minutes

  constructor(
    private jwtService: JwtService,
    private drizzle: DrizzleService,
    private cloudflareService: CloudflareService,
    private supabaseService: SupabaseService,
    private notificationsService: NotificationsService,
    private configService: ConfigService,
    private hormuudService: HormuudService,
    @Inject('REDIS_CLIENT') private readonly redis: Redis,
  ) {
    const googleClientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    this.googleClient = new OAuth2Client(googleClientId);
    this.isProduction =
      this.configService.get<string>('NODE_ENV') === 'production';
  }

  // ==========================================
  // PHONE NUMBER VALIDATION
  // ==========================================

  private normalizePhoneNumber(phoneNumber: string): string {
    const cleanedPhone = phoneNumber.trim().replace(/\s+/g, '');
    let digitsOnly = cleanedPhone.replace(/\D/g, '');

    if (digitsOnly.startsWith('252')) {
      digitsOnly = digitsOnly.substring(3);
    }

    if (digitsOnly.length !== 9) {
      throw new BadRequestException(
        `Phone number must be exactly 9 digits. Got ${digitsOnly.length} digits.`,
      );
    }

    const validPrefixes = ['61', '63', '68', '90'];
    const hasValidPrefix = validPrefixes.some((prefix) =>
      digitsOnly.startsWith(prefix),
    );

    if (!hasValidPrefix) {
      throw new BadRequestException(
        'Phone number must start with 61, 63, 68, or 90.',
      );
    }

    return '+252' + digitsOnly;
  }

  // ==========================================
  // OTP SEND - WITH HASHING
  // ==========================================
  async sendOtp(phoneNumber: string) {
    const normalizedPhone = this.normalizePhoneNumber(phoneNumber);
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

    // ✅ Hash OTP with phone number as salt
    const hashedOtp = crypto
      .createHash('sha256')
      .update(otpCode + normalizedPhone)
      .digest('hex');

    const redisKey = `otp:${normalizedPhone}`;
    const otpData: OtpCacheData = {
      otpHash: hashedOtp, // Store hash, not plain OTP
      phoneNumber: normalizedPhone,
      attempts: 0,
    };

    try {
      await this.redis.set(redisKey, JSON.stringify(otpData), {
        ex: this.OTP_TTL_SECONDS,
      });

      // ✅ Safe logging - mask phone
      this.logger.log(
        `OTP stored for ${LogSanitizer.maskPhoneNumber(normalizedPhone)}`,
      );

      if (this.isProduction) {
        await this.hormuudService.sendOtpSms(normalizedPhone, otpCode);
        this.logger.log(
          `OTP sent via SMS to ${LogSanitizer.maskPhoneNumber(normalizedPhone)}`,
        );
        return {
          message: 'OTP sent successfully',
        };
      } else {
        // ✅ Only return OTP in development AND if explicitly allowed
        const allowDebugOtp =
          this.configService.get('ALLOW_DEBUG_OTP') === 'true';

        this.logger.log(
          `[DEV] OTP sent to ${LogSanitizer.maskPhoneNumber(normalizedPhone)}`,
        );

        return {
          message: 'OTP sent successfully (Development Mode)',
          debugOtp: allowDebugOtp ? otpCode : undefined,
        };
      }
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(
        `Failed to send OTP: ${LogSanitizer.sanitizeString(errorMessage)}`,
      );
      await this.redis.del(redisKey);
      throw new BadRequestException(
        `Failed to send verification code: ${errorMessage}`,
      );
    }
  }

  // ==========================================
  // OTP VERIFY - WITH HASH CHECK
  // ==========================================
  async verifyOtp(phoneNumber: string, otpCode: string) {
    const normalizedPhone = this.normalizePhoneNumber(phoneNumber);
    const redisKey = `otp:${normalizedPhone}`;

    let otpData: OtpCacheData | null = null;

    try {
      const cachedData = await this.redis.get(redisKey);
      if (cachedData) {
        otpData =
          typeof cachedData === 'string'
            ? JSON.parse(cachedData)
            : (cachedData as OtpCacheData);
      }
    } catch (error: unknown) {
      this.logger.error('Failed to get OTP from Redis');
    }

    if (!otpData) {
      throw new UnauthorizedException(
        'OTP has expired. Please request a new one.',
      );
    }

    if (otpData.attempts >= this.MAX_OTP_ATTEMPTS) {
      await this.redis.del(redisKey);
      throw new UnauthorizedException(
        'Too many attempts. Please request a new OTP.',
      );
    }

    // ✅ Hash the input OTP and compare
    const hashedInput = crypto
      .createHash('sha256')
      .update(otpCode + normalizedPhone)
      .digest('hex');

    if (hashedInput !== otpData.otpHash) {
      otpData.attempts += 1;
      await this.redis.set(redisKey, JSON.stringify(otpData), {
        ex: this.OTP_TTL_SECONDS,
      });

      // ✅ Safe logging
      this.logger.warn(
        `Invalid OTP attempt ${otpData.attempts}/${this.MAX_OTP_ATTEMPTS} for ${LogSanitizer.maskPhoneNumber(normalizedPhone)}`,
      );

      throw new UnauthorizedException('Invalid OTP code');
    }

    // ✅ OTP is valid - delete it and proceed
    await this.redis.del(redisKey);

    const userResult = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.phoneNumber, normalizedPhone))
      .limit(1);

    let currentUser: typeof users.$inferSelect;

    if (userResult.length > 0) {
      const updatedResult = await this.drizzle.db
        .update(users)
        .set({
          isVerified: true,
          otpCode: null,
          otpExpiresAt: null,
          updatedAt: new Date(),
        })
        .where(eq(users.phoneNumber, normalizedPhone))
        .returning();

      currentUser = updatedResult[0];
    } else {
      const newUser = {
        id: uuidv4(),
        phoneNumber: normalizedPhone,
        email: null,
        name: null,
        profileImage: null,
        marketId: null,
        isVerified: true,
        isAdmin: false,
        isSuperAdmin: false,
        isActive: true,
        isOnline: false,
        otpCode: null,
        otpExpiresAt: null,
        lastSeen: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const insertResult = await this.drizzle.db
        .insert(users)
        .values(newUser)
        .returning();

      currentUser = insertResult[0];
    }

    const token = this.generateToken(
      currentUser.id,
      currentUser.isAdmin ?? false,
      currentUser.isSuperAdmin ?? false,
    );

    const hasProfile = !!(
      currentUser.name &&
      currentUser.name.trim().length > 0 &&
      currentUser.marketId &&
      currentUser.marketId.trim().length > 0
    );

    return {
      message: 'OTP verified successfully',
      token,
      user: {
        id: currentUser.id,
        phoneNumber: currentUser.phoneNumber,
        isVerified: true,
        hasProfile: hasProfile,
        name: currentUser.name,
        profileImage: currentUser.profileImage,
        isAdmin: currentUser.isAdmin ?? false,
        isSuperAdmin: currentUser.isSuperAdmin ?? false,
      },
    };
  }

  // ==========================================
  // GOOGLE SIGN-IN WITH FULL TOKEN VERIFICATION
  // ==========================================

  async googleSignIn(dto: GoogleAuthDto) {
    try {
      const payload = await this.verifyGoogleToken(dto.idToken);

      const verifiedEmail = payload.email!;
      const verifiedName = payload.name || '';
      const verifiedPicture = payload.picture || null;

      let userResult = await this.drizzle.db
        .select()
        .from(users)
        .where(eq(users.email, verifiedEmail))
        .limit(1);

      if (userResult.length === 0) {
        // New Google user
        const newUser = {
          id: uuidv4(),
          phoneNumber: '', // Empty for Google users
          email: verifiedEmail,
          name: verifiedName,
          profileImage: verifiedPicture,
          isVerified: true,
          isAdmin: false,
          isSuperAdmin: false,
          isActive: true,
          isOnline: false,
          marketId: null, // No market yet
          otpCode: null,
          otpExpiresAt: null,
          lastSeen: null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };

        await this.drizzle.db.insert(users).values(newUser);
        userResult = [newUser as typeof users.$inferSelect];
      }

      const currentUser = userResult[0];

      const hasProfile = !!(
        currentUser.phoneNumber &&
        currentUser.phoneNumber.trim().length > 0 &&
        currentUser.marketId &&
        currentUser.marketId.trim().length > 0
      );

      const token = this.generateToken(
        currentUser.id,
        currentUser.isAdmin ?? false,
        currentUser.isSuperAdmin ?? false,
      );

      // ✅ Safe logging
      this.logger.log(
        `Google sign-in successful for ${LogSanitizer.maskEmail(verifiedEmail)}`,
      );

      return {
        token,
        user: {
          id: currentUser.id,
          phoneNumber: currentUser.phoneNumber || null,
          email: currentUser.email,
          name: currentUser.name,
          profileImage: currentUser.profileImage,
          marketId: currentUser.marketId,
          isVerified: currentUser.isVerified,
          hasProfile: hasProfile,
          isAdmin: currentUser.isAdmin ?? false,
          isSuperAdmin: currentUser.isSuperAdmin ?? false,
        },
      };
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      this.logger.error('Google sign in failed');
      throw new UnauthorizedException('Google authentication failed');
    }
  }

  async facebookSignIn(dto: FacebookAuthDto) {
    this.logger.log('Facebook sign in called');

    try {
      const graphResponse = await axios.get(`https://graph.facebook.com/me`, {
        params: {
          fields: 'id,name,email,picture',
          access_token: dto.accessToken,
        },
      });

      const fbUser = graphResponse.data;
      const fbId = fbUser.id;
      const name = fbUser.name || 'Facebook User';
      const email = fbUser.email || null;
      const profileImage = fbUser.picture?.data?.url || null;

      let userResult = await this.drizzle.db
        .select()
        .from(users)
        .where(eq(users.facebookId, fbId))
        .limit(1);

      if (userResult.length === 0) {
        const newUser = {
          id: uuidv4(),
          facebookId: fbId,
          email: email,
          name: name,
          profileImage: profileImage,
          phoneNumber: null,
          isVerified: true,
          isAdmin: false,
          isSuperAdmin: false,
          isActive: true,
          isOnline: false,
          marketId: null,
          otpCode: null,
          otpExpiresAt: null,
          lastSeen: null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };

        await this.drizzle.db.insert(users).values(newUser);
        userResult = [newUser as typeof users.$inferSelect];
      }

      const currentUser = userResult[0];

      const token = this.generateToken(
        currentUser.id,
        currentUser.isAdmin ?? false,
        currentUser.isSuperAdmin ?? false,
      );

      // ✅ Safe logging
      this.logger.log(
        `Facebook sign-in successful for ${LogSanitizer.maskValue(fbId)}`,
      );

      return {
        message: 'Facebook login successful',
        token,
        user: {
          id: currentUser.id,
          phoneNumber: currentUser.phoneNumber || null,
          email: currentUser.email,
          name: currentUser.name,
          profileImage: currentUser.profileImage,
          marketId: currentUser.marketId,
          isVerified: currentUser.isVerified,
          hasProfile: !!currentUser.phoneNumber,
          isAdmin: currentUser.isAdmin ?? false,
          isSuperAdmin: currentUser.isSuperAdmin ?? false,
        },
      };
    } catch (error) {
      this.logger.error('Facebook sign in error');
      throw new UnauthorizedException('Facebook authentication failed');
    }
  }

  /**
   * ✅ Verify Google ID Token and return TokenPayload
   */
  private async verifyGoogleToken(idToken: string): Promise<TokenPayload> {
    try {
      if (!idToken || idToken.length < 20) {
        throw new UnauthorizedException('Invalid Google ID token format');
      }

      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: this.configService.get<string>('GOOGLE_CLIENT_ID'),
      });

      const payload = ticket.getPayload();

      if (!payload) {
        throw new UnauthorizedException('Invalid Google token payload');
      }

      if (!this.GOOGLE_ISSUERS.includes(payload.iss)) {
        this.logger.warn(`Invalid Google issuer: ${payload.iss}`);
        throw new UnauthorizedException('Invalid Google token issuer');
      }

      const expectedAudience =
        this.configService.get<string>('GOOGLE_CLIENT_ID');
      if (payload.aud !== expectedAudience) {
        this.logger.warn(`Invalid Google audience`);
        throw new UnauthorizedException('Invalid Google token audience');
      }

      if (!payload.email || payload.email_verified !== true) {
        this.logger.warn('Google email not verified');
        throw new UnauthorizedException('Google email is not verified');
      }

      if (payload.exp && payload.exp * 1000 < Date.now()) {
        throw new UnauthorizedException('Google token has expired');
      }

      if (payload.iat && payload.iat * 1000 > Date.now() + 300000) {
        throw new UnauthorizedException('Google token issued in the future');
      }

      return payload;
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      this.logger.error('Google token verification failed');
      throw new UnauthorizedException('Failed to verify Google token');
    }
  }

  // ==========================================
  // COMPLETE PROFILE
  // ==========================================
  async completeProfile(
    userId: string,
    data: {
      name: string;
      marketId: string;
      phoneNumber?: string;
      profileImage?: string;
    },
  ) {
    if (!data.name || !data.marketId) {
      throw new BadRequestException('Name and market are required');
    }

    const existingUserResult = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const existingUser = existingUserResult[0];

    if (
      existingUser &&
      (!existingUser.phoneNumber || existingUser.phoneNumber.trim() === '')
    ) {
      if (!data.phoneNumber || data.phoneNumber.trim() === '') {
        throw new BadRequestException(
          'Phone number is required for Google sign-in users',
        );
      }
    }

    const marketResult = await this.drizzle.db
      .select()
      .from(markets)
      .where(eq(markets.id, data.marketId))
      .limit(1);

    if (!marketResult || marketResult.length === 0) {
      throw new BadRequestException('Invalid market selected');
    }

    const updateData: UpdateUserData = {
      name: data.name,
      marketId: data.marketId,
      isVerified: true,
      updatedAt: new Date(),
    };

    if (data.phoneNumber && data.phoneNumber.trim().length > 0) {
      const cleanedPhone = data.phoneNumber.trim();
      const isGoogleUser =
        existingUser &&
        (!existingUser.phoneNumber || existingUser.phoneNumber.trim() === '');

      if (isGoogleUser) {
        const internationalPhone = cleanedPhone.replace(/\D/g, '');

        if (internationalPhone.length < 6 || internationalPhone.length > 15) {
          throw new BadRequestException(
            'Phone number must be between 6 and 15 digits',
          );
        }

        const formattedPhone = cleanedPhone.startsWith('+')
          ? cleanedPhone
          : `+${internationalPhone}`;

        // ✅ Check if phone already exists
        const existingPhone = await this.drizzle.db
          .select()
          .from(users)
          .where(eq(users.phoneNumber, formattedPhone))
          .limit(1);

        if (existingPhone.length > 0 && existingPhone[0].id !== userId) {
          throw new BadRequestException(
            'This phone number is already registered to another account.',
          );
        }

        updateData.phoneNumber = formattedPhone;
      } else {
        updateData.phoneNumber = this.normalizePhoneNumber(cleanedPhone);
      }
    }

    if (data.profileImage) {
      try {
        const uploadResult = await this.supabaseService.uploadBase64(
          data.profileImage,
          'profiles',
        );
        updateData.profileImage = uploadResult.secure_url;
      } catch (error: unknown) {
        this.logger.error('Image upload failed');
        throw new BadRequestException('Failed to upload profile image');
      }
    }

    try {
      const updatedUserResult = await this.drizzle.db
        .update(users)
        .set(updateData)
        .where(eq(users.id, userId))
        .returning();

      const updatedUser = updatedUserResult[0];

      if (!updatedUser) {
        throw new NotFoundException('User not found');
      }

      const token = this.generateToken(
        updatedUser.id,
        updatedUser.isAdmin ?? false,
        updatedUser.isSuperAdmin ?? false,
      );

      await this.notificationsService.createSystemNotification(
        userId,
        'Profile Completed',
        'Your profile has been successfully completed.',
      );

      return {
        message: 'Profile completed successfully',
        token,
        user: {
          id: updatedUser.id,
          name: updatedUser.name,
          phoneNumber: updatedUser.phoneNumber,
          email: updatedUser.email,
          profileImage: updatedUser.profileImage,
          marketId: updatedUser.marketId,
          isVerified: updatedUser.isVerified,
          hasProfile: true,
          isAdmin: updatedUser.isAdmin ?? false,
          isSuperAdmin: updatedUser.isSuperAdmin ?? false,
        },
      };
    } catch (error: unknown) {
      const err = error as {
        code?: string;
        cause?: { code?: string };
        message?: string;
      };

      if (
        err.code === '23505' ||
        err.cause?.code === '23505' ||
        err.message?.includes('users_phone_number_unique')
      ) {
        throw new BadRequestException(
          'This phone number is already registered to another account.',
        );
      }

      if (
        error instanceof BadRequestException ||
        error instanceof NotFoundException
      ) {
        throw error;
      }

      this.logger.error('Error completing profile');
      throw new BadRequestException('Failed to update profile.');
    }
  }

  // ==========================================
  // GET CURRENT USER
  // ==========================================

  async getMe(userId: string) {
    const result = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const user = result[0];

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const hasProfile = !!(
      user.phoneNumber &&
      user.phoneNumber.trim().length > 0 &&
      user.marketId &&
      user.marketId.trim().length > 0
    );

    return {
      id: user.id,
      phoneNumber: user.phoneNumber,
      email: user.email,
      name: user.name,
      profileImage: user.profileImage,
      marketId: user.marketId,
      isVerified: user.isVerified,
      hasProfile: hasProfile,
      isAdmin: user.isAdmin ?? false,
      isSuperAdmin: user.isSuperAdmin ?? false,
    };
  }

  // ==========================================
  // UPDATE PROFILE
  // ==========================================

  async updateProfile(userId: string, name?: string, marketId?: string) {
    const oldUserResult = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const oldUser = oldUserResult[0];

    const updateData: UpdateUserData = { updatedAt: new Date() };
    const changes: string[] = [];

    if (name && name !== oldUser.name) {
      updateData.name = name;
      changes.push('name');
    }
    if (marketId && marketId !== oldUser.marketId) {
      updateData.marketId = marketId;
      changes.push('market');
    }

    if (Object.keys(updateData).length === 1) {
      return {
        message: 'No changes made',
        user: {
          id: oldUser.id,
          name: oldUser.name,
          phoneNumber: oldUser.phoneNumber,
          email: oldUser.email,
          profileImage: oldUser.profileImage,
          marketId: oldUser.marketId,
          isAdmin: oldUser.isAdmin ?? false,
          isSuperAdmin: oldUser.isSuperAdmin ?? false,
        },
      };
    }

    const result = await this.drizzle.db
      .update(users)
      .set(updateData)
      .where(eq(users.id, userId))
      .returning();

    const updatedUser = result[0];

    if (changes.length > 0) {
      await this.notificationsService.createSystemNotification(
        userId,
        'Profile Updated',
        `Your profile has been updated: ${changes.join(', ')} changed.`,
      );
    }

    return {
      message: 'Profile updated successfully',
      user: {
        id: updatedUser.id,
        name: updatedUser.name,
        phoneNumber: updatedUser.phoneNumber,
        email: updatedUser.email,
        profileImage: updatedUser.profileImage,
        marketId: updatedUser.marketId,
        isAdmin: updatedUser.isAdmin ?? false,
        isSuperAdmin: updatedUser.isSuperAdmin ?? false,
      },
    };
  }

  // ==========================================
  // UPLOAD PROFILE IMAGE
  // ==========================================

  async uploadProfileImage(userId: string, base64Image: string) {
    try {
      const result = await this.supabaseService.uploadBase64(
        base64Image,
        'users/profiles',
      );

      const updatedUserResult = await this.drizzle.db
        .update(users)
        .set({
          profileImage: result.secure_url,
          updatedAt: new Date(),
        })
        .where(eq(users.id, userId))
        .returning();

      const updatedUser = updatedUserResult[0];

      await this.notificationsService.createSystemNotification(
        userId,
        'Profile Image Updated',
        'Your profile image has been updated successfully.',
      );

      return {
        message: 'Profile image uploaded successfully',
        profileImage: result.secure_url,
        publicId: result.public_id,
        user: {
          id: updatedUser.id,
          name: updatedUser.name,
          phoneNumber: updatedUser.phoneNumber,
          email: updatedUser.email,
          profileImage: updatedUser.profileImage,
          isAdmin: updatedUser.isAdmin ?? false,
          isSuperAdmin: updatedUser.isSuperAdmin ?? false,
        },
      };
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Failed to upload profile image: ${errorMessage}`);
    }
  }

  // ==========================================
  // TOKEN GENERATION - REMOVE PII
  // ==========================================
  private generateToken(
    userId: string,
    isAdmin?: boolean,
    isSuperAdmin?: boolean,
  ): string {
    const expiresIn = 90 * 24 * 60 * 60; // 90 days (3 months)

    return this.jwtService.sign(
      {
        sub: userId,
        // ❌ REMOVE: phoneNumber - don't put PII in JWT
        isAdmin: isAdmin ?? false,
        isSuperAdmin: isSuperAdmin ?? false,
      },
      {
        expiresIn,
        issuer: 'dhaqan-celiyo-app',
        audience: 'dhaqan-celiyo-users',
      },
    );
  }
}
