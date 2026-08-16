import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { DrizzleService } from '../drizzle/drizzle.service';
import { CloudflareService } from 'src/cloudfare/cloudflare.service';
import { markets, users } from '../drizzle/schema';
import { eq } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { SupabaseService } from 'src/supabase/supabase.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OAuth2Client } from 'google-auth-library';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { HormuudService } from '../hormuud/hormuud.service';

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
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private googleClient: OAuth2Client;

  constructor(
    private jwtService: JwtService,
    private drizzle: DrizzleService,
    private cloudflareService: CloudflareService,
    private supabaseService: SupabaseService,
    private notificationsService: NotificationsService,
    private configService: ConfigService,
    private hormuudService: HormuudService,
  ) {
    this.googleClient = new OAuth2Client(configService.get('GOOGLE_CLIENT_ID'));
  }

  async sendOtp(phoneNumber: string) {
    let cleanedPhone = phoneNumber.trim().replace(/\s+/g, '');

    this.logger.log(`📱 Input phone number: ${phoneNumber}`);

    // Remove any non-digit characters for analysis
    let digitsOnly = cleanedPhone.replace(/\D/g, '');

    // If starts with 252, remove it temporarily for validation
    if (digitsOnly.startsWith('252')) {
      digitsOnly = digitsOnly.substring(3);
    }

    // Validate that we have exactly 9 digits after country code
    if (digitsOnly.length !== 9) {
      throw new BadRequestException(
        `Phone number must be exactly 9 digits. Got ${digitsOnly.length} digits.`,
      );
    }

    // Check valid prefixes
    const validPrefixes = ['61', '63', '68', '90'];
    const hasValidPrefix = validPrefixes.some((prefix) =>
      digitsOnly.startsWith(prefix),
    );

    if (!hasValidPrefix) {
      throw new BadRequestException(
        `Phone number must start with 61, 63, 68, or 90. Got: ${digitsOnly.substring(0, 2)}`,
      );
    }

    // Normalize to +252 format
    cleanedPhone = '+252' + digitsOnly;
    this.logger.log(`✅ Normalized phone number: ${cleanedPhone}`);

    // Generate OTP
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000);

    // Save OTP to database
    const existingUser = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.phoneNumber, cleanedPhone))
      .limit(1);

    if (existingUser.length > 0) {
      await this.drizzle.db
        .update(users)
        .set({
          otpCode,
          otpExpiresAt,
          updatedAt: new Date(),
        })
        .where(eq(users.phoneNumber, cleanedPhone));
    } else {
      await this.drizzle.db.insert(users).values({
        id: uuidv4(),
        phoneNumber: cleanedPhone,
        otpCode,
        otpExpiresAt,
        isVerified: false,
      });
    }

    // ALWAYS send real SMS (production mode)
    try {
      await this.hormuudService.sendOtpSms(cleanedPhone, otpCode);
      this.logger.log(`✅ OTP sent via SMS to ${cleanedPhone}`);

      return {
        message: 'OTP sent successfully',
        // No debugOtp in production!
      };
    } catch (error) {
      this.logger.error(
        `Failed to send SMS to ${cleanedPhone}: ${error.message}`,
      );

      // Clean up OTP from database since SMS failed
      await this.drizzle.db
        .update(users)
        .set({
          otpCode: null,
          otpExpiresAt: null,
        })
        .where(eq(users.phoneNumber, cleanedPhone));

      throw new BadRequestException(
        `Failed to send verification code: ${error.message}`,
      );
    }
  }

  async verifyOtp(phoneNumber: string, otpCode: string) {
    this.logger.log(`Verifying OTP for ${phoneNumber}`);

    let cleanedPhone = phoneNumber.trim().replace(/\s+/g, '');
    let digitsOnly = cleanedPhone.replace(/\D/g, '');

    if (digitsOnly.startsWith('252')) {
      digitsOnly = digitsOnly.substring(3);
    }

    cleanedPhone = '+252' + digitsOnly;

    const user = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.phoneNumber, cleanedPhone))
      .limit(1);

    if (!user.length) {
      throw new UnauthorizedException('User not found');
    }

    const currentUser = user[0];

    if (currentUser.otpCode !== otpCode) {
      throw new UnauthorizedException('Invalid OTP code');
    }

    if (currentUser.otpExpiresAt && new Date() > currentUser.otpExpiresAt) {
      throw new UnauthorizedException('OTP has expired');
    }

    await this.drizzle.db
      .update(users)
      .set({
        isVerified: true,
        otpCode: null,
        otpExpiresAt: null,
        updatedAt: new Date(),
      })
      .where(eq(users.phoneNumber, cleanedPhone));

    const token = this.generateToken(
      currentUser.id,
      cleanedPhone,
      currentUser.isAdmin ?? false,
      currentUser.isSuperAdmin ?? false,
    );

    const hasProfile = !!(
      currentUser.name && currentUser.name.trim().length > 0
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

  async googleSignIn(dto: GoogleAuthDto) {
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken: dto.idToken,
        audience: this.configService.get('GOOGLE_CLIENT_ID'),
      });

      const payload = ticket.getPayload();
      if (!payload || !payload.email) {
        throw new UnauthorizedException('Invalid Google token');
      }

      let user = await this.drizzle.db
        .select()
        .from(users)
        .where(eq(users.email, dto.email))
        .limit(1);

      if (user.length === 0) {
        const newUser = {
          id: uuidv4(),
          phoneNumber: '',
          email: dto.email,
          name: dto.name,
          profileImage: dto.photoUrl || null,
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
        user = [newUser as any];
      } else {
        await this.drizzle.db
          .update(users)
          .set({
            name: dto.name,
            profileImage: dto.photoUrl || user[0].profileImage,
            updatedAt: new Date(),
          })
          .where(eq(users.email, dto.email));

        user = await this.drizzle.db
          .select()
          .from(users)
          .where(eq(users.email, dto.email))
          .limit(1);
      }

      const currentUser = user[0];
      const hasProfile = !!(
        currentUser.name &&
        currentUser.name.trim().length > 0 &&
        currentUser.marketId
      );

      const token = this.generateToken(
        currentUser.id,
        currentUser.phoneNumber || '',
        currentUser.isAdmin ?? false,
        currentUser.isSuperAdmin ?? false,
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
      this.logger.error('Google sign in error:', error);
      throw new UnauthorizedException('Google authentication failed');
    }
  }

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

    const [existingUser] = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

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

    const updateData: any = {
      name: data.name,
      marketId: data.marketId,
      isVerified: true,
      updatedAt: new Date(),
    };

    if (data.phoneNumber && data.phoneNumber.trim().length > 0) {
      let cleanedPhone = data.phoneNumber.trim();
      let digitsOnly = cleanedPhone.replace(/\D/g, '');

      if (digitsOnly.startsWith('252')) {
        digitsOnly = digitsOnly.substring(3);
      }

      updateData.phoneNumber = '+252' + digitsOnly;
    }

    if (data.profileImage) {
      try {
        const uploadResult = await this.supabaseService.uploadBase64(
          data.profileImage,
          'profiles',
        );
        updateData.profileImage = uploadResult.secure_url;
      } catch (error) {
        this.logger.error('Image upload failed:', error);
        throw new BadRequestException('Failed to upload profile image');
      }
    }

    try {
      const [updatedUser] = await this.drizzle.db
        .update(users)
        .set(updateData)
        .where(eq(users.id, userId))
        .returning();

      if (!updatedUser) {
        throw new NotFoundException('User not found');
      }

      const token = this.generateToken(
        updatedUser.id,
        updatedUser.phoneNumber as string,
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
    } catch (error: any) {
      if (
        error.code === '23505' ||
        error.cause?.code === '23505' ||
        error.message?.includes('users_phone_number_unique')
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

      this.logger.error('Error completing profile:', error);
      throw new BadRequestException('Failed to update profile.');
    }
  }

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

    const hasProfile = !!(user.name && user.name.trim().length > 0);

    return {
      id: user.id,
      phoneNumber: user.phoneNumber,
      name: user.name,
      profileImage: user.profileImage,
      marketId: user.marketId,
      isVerified: user.isVerified,
      hasProfile: hasProfile,
      isAdmin: user.isAdmin ?? false,
      isSuperAdmin: user.isSuperAdmin ?? false,
    };
  }

  async updateProfile(userId: string, name?: string, marketId?: string) {
    const [oldUser] = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const updateData: Partial<User> = { updatedAt: new Date() };
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
        profileImage: updatedUser.profileImage,
        marketId: updatedUser.marketId,
        isAdmin: updatedUser.isAdmin ?? false,
        isSuperAdmin: updatedUser.isSuperAdmin ?? false,
      },
    };
  }

  async uploadProfileImage(userId: string, base64Image: string) {
    try {
      const result = await this.supabaseService.uploadBase64(
        base64Image,
        'users/profiles',
      );

      const [updatedUser] = await this.drizzle.db
        .update(users)
        .set({
          profileImage: result.secure_url,
          updatedAt: new Date(),
        })
        .where(eq(users.id, userId))
        .returning();

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

  private generateToken(
    userId: string,
    phoneNumber: string,
    isAdmin?: boolean,
    isSuperAdmin?: boolean,
  ): string {
    const expiresIn = 364 * 24 * 60 * 60; // 1 year
    return this.jwtService.sign(
      {
        sub: userId,
        phoneNumber,
        isAdmin: isAdmin ?? false,
        isSuperAdmin: isSuperAdmin ?? false,
      },
      { expiresIn },
    );
  }
}
