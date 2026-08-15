import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
  NotFoundException,
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
import type { users as UsersType } from '../drizzle/schema';

interface User {
  id: string;
  phoneNumber: string;
  email: string | null;
  name: string | null;
  profileImage: string | null;
  marketId: string | null;
  isVerified: boolean | null;
  isAdmin: boolean | null;
  isSuperAdmin: boolean | null; // ✅ ADD THIS
  otpCode: string | null;
  otpExpiresAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client;
  constructor(
    private jwtService: JwtService,
    private drizzle: DrizzleService,
    private cloudflareService: CloudflareService,
    private supabaseService: SupabaseService,
    private notificationsService: NotificationsService,
    private configService: ConfigService,
  ) {
    this.googleClient = new OAuth2Client(configService.get('GOOGLE_CLIENT_ID'));
  }
  // auth.service.ts - Updated sendOtp method

  async sendOtp(phoneNumber: string) {
    let cleanedPhone = phoneNumber.trim().replace(/\s+/g, '');

    // ✅ Support all Somali telecom providers
    // Check if it's a local number (starts with 61, 68, 90, or 63)
    const validPrefixes = ['61', '68', '90', '63'];
    let isValidPrefix = false;

    for (const prefix of validPrefixes) {
      if (cleanedPhone.startsWith(prefix)) {
        isValidPrefix = true;
        break;
      }
    }

    // If it starts with a valid prefix, format as +252
    if (isValidPrefix) {
      cleanedPhone = '+252' + cleanedPhone;
    }
    // If it starts with 0 and valid prefix
    else if (cleanedPhone.startsWith('0') && cleanedPhone.length >= 3) {
      const withoutZero = cleanedPhone.substring(1);
      for (const prefix of validPrefixes) {
        if (withoutZero.startsWith(prefix)) {
          cleanedPhone = '+252' + withoutZero;
          isValidPrefix = true;
          break;
        }
      }
    }
    // If it already has +252 prefix with valid prefix
    else if (cleanedPhone.startsWith('+252') && cleanedPhone.length >= 7) {
      const withoutPlus = cleanedPhone.substring(4);
      for (const prefix of validPrefixes) {
        if (withoutPlus.startsWith(prefix)) {
          isValidPrefix = true;
          break;
        }
      }
    }

    // ✅ Validate the final phone number
    if (!isValidPrefix || !cleanedPhone.startsWith('+252')) {
      throw new BadRequestException(
        'Invalid Somali phone number format. Supported: 61, 63, 68, 90',
      );
    }

    // ✅ Validate length (should be +252 + 9 digits = 13 chars)
    if (cleanedPhone.length !== 13) {
      throw new BadRequestException(
        'Phone number must be exactly 9 digits after the country code',
      );
    }

    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000);

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

    console.log(`OTP for ${cleanedPhone}: ${otpCode}`);

    return {
      message: 'OTP sent successfully',
      debugOtp: otpCode,
    };
  }

  // src/auth/auth.service.ts - Replace the googleSignIn method with this

  async googleSignIn(dto: GoogleAuthDto) {
    try {
      // Verify the Google ID token
      const ticket = await this.googleClient.verifyIdToken({
        idToken: dto.idToken,
        audience: this.configService.get('GOOGLE_CLIENT_ID'),
      });

      const payload = ticket.getPayload();
      if (!payload || !payload.email) {
        throw new UnauthorizedException('Invalid Google token');
      }

      // Check if user exists by email
      let user = await this.drizzle.db
        .select()
        .from(users)
        .where(eq(users.email, dto.email))
        .limit(1);

      if (user.length === 0) {
        // Create new user with required phoneNumber field (empty string as placeholder)
        const newUser = {
          id: uuidv4(),
          phoneNumber: '', // ✅ Required field - empty string for Google users
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
        user = [newUser as unknown as typeof user[0]]; // Type assertion to match User interface
      } else {
        // Update existing user
        await this.drizzle.db
          .update(users)
          .set({
            name: dto.name,
            profileImage: dto.photoUrl || user[0].profileImage,
            updatedAt: new Date(),
          })
          .where(eq(users.email, dto.email));

        // Refetch updated user
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
        currentUser.marketId // ✅ Check if marketId exists too
      );

      const token = this.generateToken(
        currentUser.id,
        currentUser.phoneNumber || '',
        currentUser.isAdmin ?? false,
        currentUser.isSuperAdmin ?? false,
      );

      // ✅ Don't send empty phoneNumber to the client
      return {
        token,
        user: {
          id: currentUser.id,
          phoneNumber: currentUser.phoneNumber || null, // ✅ Send null if empty
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
      console.error('Google sign in error:', error);
      throw new UnauthorizedException('Google authentication failed');
    }
  }

  async verifyOtp(phoneNumber: string, otpCode: string) {
    console.log(phoneNumber);
    console.log(otpCode);

    const user = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.phoneNumber, phoneNumber))
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
      .where(eq(users.phoneNumber, phoneNumber));

    const token = this.generateToken(
      currentUser.id,
      phoneNumber,
      currentUser.isAdmin ?? false,
      currentUser.isSuperAdmin ?? false, // ✅ Pass isSuperAdmin
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
        isSuperAdmin: currentUser.isSuperAdmin ?? false, // ✅ ADD THIS
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
          isSuperAdmin: updatedUser.isSuperAdmin ?? false, // ✅ ADD THIS
        },
      };
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Failed to upload profile image: ${errorMessage}`);
    }
  }

  // src/auth/auth.service.ts - Update the completeProfile method

  async completeProfile(
    userId: string,
    data: {
      name: string;
      marketId: string;
      phoneNumber?: string;
      profileImage?: string;
    },
  ) {
    console.log('🔍 Completing profile for user:', userId);
    console.log('📦 Data received:', data);

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
      console.error('❌ Market not found:', data.marketId);
      throw new BadRequestException('Invalid market selected');
    }

    const market = marketResult[0];
    console.log('✅ Market found:', market.name);

    const updateData: any = {
      name: data.name,
      marketId: data.marketId,
      isVerified: true,
      updatedAt: new Date(),
    };

    if (data.phoneNumber && data.phoneNumber.trim().length > 0) {
      const cleanedPhone = data.phoneNumber.trim();
      const validPrefixes = ['61', '68', '90', '63'];
      let isValid = false;

      for (const prefix of validPrefixes) {
        if (
          cleanedPhone.startsWith('+252' + prefix) ||
          cleanedPhone.startsWith(prefix)
        ) {
          isValid = true;
          break;
        }
      }

      if (!isValid) {
        throw new BadRequestException('Invalid Somali phone number format');
      }

      let formattedPhone = cleanedPhone;
      if (!formattedPhone.startsWith('+252')) {
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+252' + formattedPhone.substring(1);
        } else {
          formattedPhone = '+252' + formattedPhone;
        }
      }

      updateData.phoneNumber = formattedPhone;
      console.log('📱 Phone number updated:', formattedPhone);
    }

    if (data.profileImage) {
      try {
        console.log('📸 Uploading profile image...');
        const uploadResult = await this.supabaseService.uploadBase64(
          data.profileImage,
          'profiles',
        );
        updateData.profileImage = uploadResult.secure_url;
        console.log('✅ Image uploaded:', uploadResult.secure_url);
      } catch (error) {
        console.error('❌ Image upload failed:', error);
        throw new BadRequestException('Failed to upload profile image');
      }
    }

    // ✅ WRAP DATABASE UPDATE IN TRY-CATCH TO HANDLE DUPLICATE PHONE NUMBERS
    try {
      const [updatedUser] = await this.drizzle.db
        .update(users)
        .set(updateData)
        .where(eq(users.id, userId))
        .returning();

      if (!updatedUser) {
        throw new NotFoundException('User not found');
      }

      console.log('✅ Profile completed successfully');
      console.log('📱 Final phone number:', updatedUser.phoneNumber);

      const token = this.jwtService.sign({
        sub: updatedUser.id,
        phoneNumber: updatedUser.phoneNumber,
        isAdmin: updatedUser.isAdmin ?? false,
        isSuperAdmin: updatedUser.isSuperAdmin ?? false,
      });

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
    } catch (error) {
      // ✅ Catch Postgres Unique Constraint Violation (Error Code 23505)
      const errorCode = (error as any)?.code || (error as any)?.cause?.code;
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      
      if (
        errorCode === '23505' ||
        errorMessage?.includes('users_phone_number_unique')
      ) {
        console.warn(
          `⚠️ Duplicate phone number attempt: ${updateData.phoneNumber}`,
        );
        throw new BadRequestException(
          'This phone number is already registered to another account. Please use a different number.',
        );
      }

      // Re-throw other NestJS exceptions (like NotFoundException)
      if (
        error instanceof BadRequestException ||
        error instanceof NotFoundException
      ) {
        throw error;
      }

      // Log unexpected errors for debugging
      console.error('❌ Error completing profile:', error);
      throw new BadRequestException(
        'Failed to update profile due to a server error. Please try again.',
      );
    }
  }

  async getMe(userId: string) {
    try {
      console.log(`📖 Fetching user: ${userId}`);

      const result = await this.drizzle.db
        .select()
        .from(users)
        .where(eq(users.id, userId))
        .limit(1);

      const user = result[0];

      if (!user) {
        console.log(`❌ User not found: ${userId}`);
        throw new UnauthorizedException('User not found');
      }

      const hasProfile = !!(user.name && user.name.trim().length > 0);

      console.log(`✅ User found: ${user.id}, hasProfile: ${hasProfile}`);

      return {
        id: user.id,
        phoneNumber: user.phoneNumber,
        name: user.name,
        profileImage: user.profileImage,
        marketId: user.marketId,
        isVerified: user.isVerified,
        hasProfile: hasProfile,
        isAdmin: user.isAdmin ?? false,
        isSuperAdmin: user.isSuperAdmin ?? false, // ✅ ADD THIS
      };
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      console.error(`❌ Error in getMe: ${errorMessage}`);
      throw error;
    }
  }

  async updateProfile(userId: string, name?: string, marketId?: string) {
    try {
      console.log(
        ` Updating profile: userId=${userId}, name=${name}, marketId=${marketId}`,
      );

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
        const result = await this.drizzle.db
          .select()
          .from(users)
          .where(eq(users.id, userId))
          .limit(1);
        const user = result[0];
        return {
          message: 'No changes made',
          user: {
            id: user.id,
            name: user.name,
            phoneNumber: user.phoneNumber,
            profileImage: user.profileImage,
            marketId: user.marketId,
            isAdmin: user.isAdmin ?? false,
            isSuperAdmin: user.isSuperAdmin ?? false, // ✅ ADD THIS
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
        const changeMessage = changes.join(', ');
        await this.notificationsService.createSystemNotification(
          userId,
          'Profile Updated',
          `Your profile has been updated: ${changeMessage} changed.`,
        );
      }

      console.log(`✅ Profile updated for user: ${userId}`);

      return {
        message: 'Profile updated successfully',
        user: {
          id: updatedUser.id,
          name: updatedUser.name,
          phoneNumber: updatedUser.phoneNumber,
          profileImage: updatedUser.profileImage,
          marketId: updatedUser.marketId,
          isAdmin: updatedUser.isAdmin ?? false,
          isSuperAdmin: updatedUser.isSuperAdmin ?? false, // ✅ ADD THIS
        },
      };
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      console.error(`❌ Error updating profile: ${errorMessage}`);
      throw error;
    }
  }

  private generateToken(
    userId: string,
    phoneNumber: string,
    isAdmin?: boolean,
    isSuperAdmin?: boolean, // ✅ ADD THIS
  ): string {
    const expiresIn = 14 * 24 * 60 * 60; // 14 days in seconds
    return this.jwtService.sign(
      {
        sub: userId,
        phoneNumber,
        isAdmin: isAdmin ?? false,
        isSuperAdmin: isSuperAdmin ?? false, // ✅ ADD THIS
      },
      { expiresIn: expiresIn },
    );
  }
}
