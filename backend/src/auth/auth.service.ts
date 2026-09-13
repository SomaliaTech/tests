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

interface UpdateUserData {
  name?: string;
  marketId?: string;
  phoneNumber?: string;
  profileImage?: string;
  email?: string;
  isVerified?: boolean;
  isActive?: boolean;
  updatedAt: Date;
}

interface OtpCacheData {
  otpHash: string;
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
  private readonly DELETION_GRACE_DAYS = 15;

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

    const hashedOtp = crypto
      .createHash('sha256')
      .update(otpCode + normalizedPhone)
      .digest('hex');

    const redisKey = `otp:${normalizedPhone}`;
    const otpData: OtpCacheData = {
      otpHash: hashedOtp,
      phoneNumber: normalizedPhone,
      attempts: 0,
    };

    try {
      await this.redis.set(redisKey, JSON.stringify(otpData), {
        ex: this.OTP_TTL_SECONDS,
      });

      this.logger.log(
        `OTP stored for ${LogSanitizer.maskPhoneNumber(normalizedPhone)}`,
      );

      if (
        !this.isProduction &&
        this.configService.get('ALLOW_DEBUG_OTP') === 'true'
      ) {
        this.logger.debug(
          `[DEV] OTP for ${LogSanitizer.maskPhoneNumber(normalizedPhone)}: ${otpCode}`,
        );
      }

      if (this.isProduction) {
        await this.hormuudService.sendOtpSms(normalizedPhone, otpCode);
        this.logger.log(
          `OTP sent via SMS to ${LogSanitizer.maskPhoneNumber(normalizedPhone)}`,
        );
        return {
          message: 'OTP sent successfully',
        };
      } else {
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
  // OTP VERIFY - WITH HASH CHECK + AUTO RESTORE
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

    const hashedInput = crypto
      .createHash('sha256')
      .update(otpCode + normalizedPhone)
      .digest('hex');

    if (hashedInput !== otpData.otpHash) {
      otpData.attempts += 1;
      await this.redis.set(redisKey, JSON.stringify(otpData), {
        ex: this.OTP_TTL_SECONDS,
      });

      this.logger.warn(
        `Invalid OTP attempt ${otpData.attempts}/${this.MAX_OTP_ATTEMPTS} for ${LogSanitizer.maskPhoneNumber(normalizedPhone)}`,
      );

      throw new UnauthorizedException('Invalid OTP code');
    }

    await this.redis.del(redisKey);

    const userResult = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.phoneNumber, normalizedPhone))
      .limit(1);

    let currentUser: typeof users.$inferSelect;

    if (userResult.length > 0) {
      // ✅ Guard: block if permanently past deletion date
      this.assertNotPermanentlyDeleted(userResult[0]);

      // ✅ Auto-restore if scheduled for deletion
      await this.restoreAccountIfDeleted(userResult[0].id);

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
        deletedAt: null,
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
  // GOOGLE SIGN-IN + AUTO RESTORE
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
        const newUser = {
          id: uuidv4(),
          phoneNumber: null,
          email: verifiedEmail,
          name: verifiedName,
          profileImage: verifiedPicture,
          isVerified: true,
          isAdmin: false,
          isSuperAdmin: false,
          isActive: true,
          isOnline: false,
          marketId: null,
          otpCode: null,
          otpExpiresAt: null,
          lastSeen: null,
          deletedAt: null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };

        await this.drizzle.db.insert(users).values(newUser);
        userResult = [newUser as typeof users.$inferSelect];
      } else {
        // ✅ Guard + restore
        this.assertNotPermanentlyDeleted(userResult[0]);
        await this.restoreAccountIfDeleted(userResult[0].id);

        // Refetch
        const fresh = await this.drizzle.db
          .select()
          .from(users)
          .where(eq(users.id, userResult[0].id))
          .limit(1);
        userResult = fresh;
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

  // ==========================================
  // FACEBOOK SIGN-IN + AUTO RESTORE
  // ==========================================
  async facebookSignIn(dto: FacebookAuthDto) {
    this.logger.log('Facebook sign in called');

    try {
      const isLimitedLoginJwt =
        dto.accessToken.startsWith('eyJ') &&
        dto.accessToken.split('.').length === 3;

      const fbUser = isLimitedLoginJwt
        ? await this.verifyFacebookLimitedLoginToken(dto.accessToken)
        : await this.verifyFacebookToken(dto.accessToken);

      const fbId = fbUser.id;
      const name = fbUser.name || null;
      const email = fbUser.email || null;
      const profileImage = fbUser.picture?.data?.url || null;

      let userResult = await this.drizzle.db
        .select()
        .from(users)
        .where(eq(users.facebookId, fbId))
        .limit(1);

      if (userResult.length === 0 && email) {
        userResult = await this.drizzle.db
          .select()
          .from(users)
          .where(eq(users.email, email))
          .limit(1);
      }

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
          deletedAt: null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };

        await this.drizzle.db.insert(users).values(newUser);
        userResult = [newUser as typeof users.$inferSelect];
      } else {
        // ✅ Guard + restore
        this.assertNotPermanentlyDeleted(userResult[0]);
        await this.restoreAccountIfDeleted(userResult[0].id);

        await this.drizzle.db
          .update(users)
          .set({
            facebookId: fbId,
            name: name || userResult[0].name,
            profileImage: profileImage || userResult[0].profileImage,
            updatedAt: new Date(),
          })
          .where(eq(users.id, userResult[0].id));

        userResult = await this.drizzle.db
          .select()
          .from(users)
          .where(eq(users.id, userResult[0].id))
          .limit(1);
      }

      const currentUser = userResult[0];

      const token = this.generateToken(
        currentUser.id,
        currentUser.isAdmin ?? false,
        currentUser.isSuperAdmin ?? false,
      );

      const hasCompleteProfile = !!(
        currentUser.name &&
        currentUser.name.trim().length > 0 &&
        currentUser.phoneNumber &&
        currentUser.phoneNumber.trim().length > 0 &&
        currentUser.marketId &&
        currentUser.marketId.trim().length > 0
      );

      this.logger.log(
        `Facebook sign-in successful for ${LogSanitizer.maskValue(fbId)} - hasProfile: ${hasCompleteProfile}`,
      );

      return {
        message: 'Facebook login successful',
        token,
        user: {
          id: currentUser.id,
          phoneNumber: currentUser.phoneNumber || '',
          email: currentUser.email,
          name: currentUser.name || '',
          profileImage: currentUser.profileImage,
          marketId: currentUser.marketId,
          isVerified: currentUser.isVerified,
          hasProfile: hasCompleteProfile,
          isAdmin: currentUser.isAdmin ?? false,
          isSuperAdmin: currentUser.isSuperAdmin ?? false,
        },
      };
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;

      this.logger.error('Facebook sign in error');

      if (axios.isAxiosError(error)) {
        if (error.code === 'ECONNABORTED') {
          throw new UnauthorizedException(
            'Facebook verification timed out. Please try again.',
          );
        }
        if (error.response?.status === 400) {
          throw new UnauthorizedException(
            'Invalid Facebook token. Please login again.',
          );
        }
        this.logger.error(`Facebook API error: ${error.message}`);
      }

      throw new UnauthorizedException('Facebook authentication failed');
    }
  }

  // ==========================================
  // FACEBOOK VERIFICATION HELPERS
  // ==========================================
  private async verifyFacebookToken(
    accessToken: string,
    maxRetries = 2,
  ): Promise<any> {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const response = await axios.get(`https://graph.facebook.com/me`, {
          params: {
            fields: 'id,name,email,picture',
            access_token: accessToken,
          },
          timeout: 10000,
        });
        return response.data;
      } catch (error) {
        if (attempt === maxRetries) throw error;
        await new Promise((resolve) => setTimeout(resolve, 2000 * attempt));
      }
    }
  }

  private facebookJwksCache: { keys: any[]; fetchedAt: number } | null = null;

  private async getFacebookJwks(): Promise<any[]> {
    const now = Date.now();
    if (
      this.facebookJwksCache &&
      now - this.facebookJwksCache.fetchedAt < 60 * 60 * 1000
    ) {
      return this.facebookJwksCache.keys;
    }

    const res = await axios.get(
      'https://www.facebook.com/.well-known/oauth/openid/jwks/',
      { timeout: 10000 },
    );
    this.facebookJwksCache = { keys: res.data.keys, fetchedAt: now };
    return res.data.keys as any[];
  }

  private decodeJwtPart(part: string): any {
    const normalized = part.replace(/-/g, '+').replace(/_/g, '/');
    return JSON.parse(Buffer.from(normalized, 'base64').toString('utf8'));
  }

  private async verifyFacebookLimitedLoginToken(idToken: string): Promise<{
    id: string;
    name: string | null;
    email: string | null;
    picture: { data: { url: string } } | null;
  }> {
    const parts = idToken.split('.');
    if (parts.length !== 3) {
      throw new UnauthorizedException('Invalid Facebook ID token format');
    }

    const header = this.decodeJwtPart(parts[0]);
    const payload = this.decodeJwtPart(parts[1]);

    if (payload.iss && !String(payload.iss).includes('facebook.com')) {
      throw new UnauthorizedException('Invalid Facebook token issuer');
    }

    const validAppIds = [
      '869167092793903',
      '476493349999779',
      this.configService.get<string>('FACEBOOK_APP_ID'),
    ].filter((id): id is string => !!id);

    if (payload.aud && !validAppIds.includes(payload.aud)) {
      this.logger.warn(
        `❌ Facebook audience mismatch! Backend accepts: ${validAppIds.join(', ')}, but token has: ${payload.aud}`,
      );
      throw new UnauthorizedException('Invalid Facebook token audience');
    }

    if (payload.exp && payload.exp * 1000 < Date.now()) {
      throw new UnauthorizedException('Facebook token expired');
    }

    if (!payload.sub) {
      throw new UnauthorizedException('Facebook token missing user id');
    }

    try {
      const keys = await this.getFacebookJwks();
      const jwk = keys.find((k) => k.kid === header.kid);
      if (!jwk) throw new Error('No matching Facebook JWK');

      const publicKey = crypto.createPublicKey({
        key: jwk,
        format: 'jwk',
      });

      const signedData = Buffer.from(`${parts[0]}.${parts[1]}`);
      const signature = Buffer.from(
        parts[2].replace(/-/g, '+').replace(/_/g, '/'),
        'base64',
      );

      const isValid = crypto.verify(
        'RSA-SHA256',
        signedData,
        publicKey,
        signature,
      );
      if (!isValid) throw new Error('Bad signature');
    } catch (e) {
      this.logger.error(`Limited Login verification failed: ${e}`);
      throw new UnauthorizedException('Failed to verify Facebook token');
    }

    const pictureUrl =
      typeof payload.picture === 'string'
        ? payload.picture
        : payload.picture?.data?.url || null;

    return {
      id: payload.sub,
      name: payload.name || null,
      email: payload.email || null,
      picture: pictureUrl ? { data: { url: pictureUrl } } : null,
    };
  }

  // ==========================================
  // GOOGLE TOKEN VERIFICATION
  // ==========================================
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

    this.assertNotPermanentlyDeleted(user);

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
  async updateProfile(
    userId: string,
    name?: string,
    marketId?: string,
    email?: string,
  ) {
    const oldUserResult = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const oldUser = oldUserResult[0];

    if (!oldUser) {
      throw new NotFoundException('User not found');
    }

    this.assertNotPermanentlyDeleted(oldUser);

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
    if (email && email !== oldUser.email) {
      updateData.email = email;
      changes.push('email');
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
  // ✅ SOFT DELETE ACCOUNT (60-day recovery)
  // ==========================================
  async deleteAccount(userId: string) {
    const result = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const user = result[0];
    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.deletedAt) {
      return {
        message: 'Account is already scheduled for deletion',
        scheduledDeletionDate: user.deletedAt.toISOString(),
      };
    }

    const now = new Date();
    const deletionDate = new Date(
      now.getTime() + this.DELETION_GRACE_DAYS * 24 * 60 * 60 * 1000,
    );

    await this.drizzle.db
      .update(users)
      .set({
        deletedAt: deletionDate,
        isOnline: false,
        updatedAt: now,
      })
      .where(eq(users.id, userId));

    this.logger.log(
      `Account scheduled for deletion: userId=${LogSanitizer.maskValue(userId)}, deleteAt=${deletionDate.toISOString()}`,
    );

    try {
      await this.notificationsService.createSystemNotification(
        userId,
        'Account Deletion Scheduled',
        `Your account will be permanently deleted on ${deletionDate.toDateString()}. Log back in before then to cancel.`,
      );
    } catch (e) {
      this.logger.warn('Failed to create deletion notification');
    }

    return {
      message: `Account scheduled for deletion on ${deletionDate.toDateString()}. You have ${this.DELETION_GRACE_DAYS} days to log back in and restore it.`,
      scheduledDeletionDate: deletionDate.toISOString(),
    };
  }

  // ==========================================
  // ✅ AUTO-RESTORE HELPER
  // ==========================================
  private async restoreAccountIfDeleted(userId: string): Promise<boolean> {
    const result = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const user = result[0];
    if (!user || !user.deletedAt) return false;

    if (user.deletedAt.getTime() <= Date.now()) {
      this.logger.warn(
        `User ${LogSanitizer.maskValue(userId)} attempted to log in after deletion date — refusing restore`,
      );
      throw new UnauthorizedException(
        'Your account has been permanently deleted and cannot be restored.',
      );
    }

    await this.drizzle.db
      .update(users)
      .set({
        deletedAt: null,
        isActive: true,
        updatedAt: new Date(),
      })
      .where(eq(users.id, userId));

    this.logger.log(
      `Account restored for userId=${LogSanitizer.maskValue(userId)}`,
    );

    return true;
  }

  // ==========================================
  // ✅ GUARD: refuse if deletion date has passed
  // ==========================================
  private assertNotPermanentlyDeleted(user: {
    deletedAt?: Date | null;
    id: string;
  }) {
    if (user.deletedAt && user.deletedAt.getTime() <= Date.now()) {
      throw new UnauthorizedException(
        'Your account has been permanently deleted.',
      );
    }
  }

  // ==========================================
  // TOKEN GENERATION
  // ==========================================
  private generateToken(
    userId: string,
    isAdmin?: boolean,
    isSuperAdmin?: boolean,
  ): string {
    const expiresIn = 90 * 24 * 60 * 60; // 90 days

    return this.jwtService.sign(
      {
        sub: userId,
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
