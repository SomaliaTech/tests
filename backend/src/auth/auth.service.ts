import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
  NotFoundException, // ✅ ADDED
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

interface User {
  id: string;
  phoneNumber: string;
  email: string | null;
  name: string | null;
  profileImage: string | null;
  marketId: string | null;
  isVerified: boolean | null;
  isAdmin: boolean | null;
  otpCode: string | null;
  otpExpiresAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class AuthService {
  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private drizzle: DrizzleService,
    private cloudflareService: CloudflareService,
    private supabaseService: SupabaseService,
    private notificationsService: NotificationsService,
  ) {}

  async sendOtp(phoneNumber: string) {
    let cleanedPhone = phoneNumber.trim().replace(/\s+/g, '');

    if (cleanedPhone.startsWith('61') || cleanedPhone.startsWith('061')) {
      cleanedPhone = '+252' + cleanedPhone.replace(/^0?/, '');
    } else if (cleanedPhone.startsWith('25261')) {
      cleanedPhone = '+' + cleanedPhone;
    } else if (!cleanedPhone.startsWith('+25261')) {
      throw new BadRequestException('Invalid Somali phone number format');
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
        email: currentUser.email,
        profileImage: currentUser.profileImage,
        isAdmin: currentUser.isAdmin ?? false,
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
          email: updatedUser.email,
          phoneNumber: updatedUser.phoneNumber,
          profileImage: updatedUser.profileImage,
          isAdmin: updatedUser.isAdmin ?? false,
        },
      };
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Failed to upload profile image: ${errorMessage}`);
    }
  }

  async completeProfile(
    userId: string,
    data: {
      name: string;
      email: string;
      marketId: string;
      profileImage?: string;
    },
  ) {
    console.log('🔍 Completing profile for user:', userId);
    console.log('📦 Data received:', data);

    // ✅ Validate required fields
    if (!data.name || !data.email || !data.marketId) {
      throw new BadRequestException('Name, email, and market are required');
    }

    // ✅ Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(data.email)) {
      throw new BadRequestException('Invalid email format');
    }

    // ✅ Validate market exists
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

    // ✅ Check if email is already taken
    const existingEmail = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.email, data.email))
      .limit(1);

    if (existingEmail.length > 0 && existingEmail[0].id !== userId) {
      throw new BadRequestException('Email already in use');
    }

    const updateData: any = {
      name: data.name,
      email: data.email,
      marketId: data.marketId,
      isVerified: true,
      updatedAt: new Date(),
    };

    // ✅ Handle profile image upload if provided
    if (data.profileImage) {
      try {
        console.log('📸 Uploading profile image...');
        const uploadResult = await this.supabaseService.uploadBase64(
          data.profileImage,
          'profiles',
        );
        // ✅ FIXED: Use secure_url instead of url
        updateData.profileImage = uploadResult.secure_url;
        console.log('✅ Image uploaded:', uploadResult.secure_url);
      } catch (error) {
        console.error('❌ Image upload failed:', error);
        throw new BadRequestException('Failed to upload profile image');
      }
    }

    // ✅ Update user
    const [updatedUser] = await this.drizzle.db
      .update(users)
      .set(updateData)
      .where(eq(users.id, userId))
      .returning();

    if (!updatedUser) {
      throw new NotFoundException('User not found');
    }

    console.log('✅ Profile completed successfully');

    // ✅ Generate new token with updated user data
    // In completeProfile method (already correct, but verify)
    const token = this.jwtService.sign({
      sub: updatedUser.id,
      phoneNumber: updatedUser.phoneNumber,
      isAdmin: updatedUser.isAdmin ?? false, // ✅ Already correct in completeProfile
    });
    // ✅ Send notification for profile completion
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
        email: updatedUser.email,
        phoneNumber: updatedUser.phoneNumber,
        profileImage: updatedUser.profileImage,
        marketId: updatedUser.marketId,
        isVerified: updatedUser.isVerified,
        hasProfile: true,
        isAdmin: updatedUser.isAdmin ?? false,
      },
    };
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
        email: user.email,
        profileImage: user.profileImage,
        marketId: user.marketId,
        isVerified: user.isVerified,
        hasProfile: hasProfile,
        isAdmin: user.isAdmin ?? false,
      };
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      console.error(`❌ Error in getMe: ${errorMessage}`);
      throw error;
    }
  }

  async updateProfile(
    userId: string,
    name?: string,
    email?: string,
    marketId?: string,
  ) {
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
      if (email && email !== oldUser.email) {
        updateData.email = email;
        changes.push('email');
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
            email: user.email,
            phoneNumber: user.phoneNumber,
            profileImage: user.profileImage,
            marketId: user.marketId,
            isAdmin: user.isAdmin ?? false,
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
          email: updatedUser.email,
          phoneNumber: updatedUser.phoneNumber,
          profileImage: updatedUser.profileImage,
          marketId: updatedUser.marketId,
          isAdmin: updatedUser.isAdmin ?? false,
        },
      };
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      console.error(`❌ Error updating profile: ${errorMessage}`);
      throw error;
    }
  }

  // ✅ Fixed - Include isAdmin
  private generateToken(
    userId: string,
    phoneNumber: string,
    isAdmin?: boolean,
  ): string {
    const expiresIn = 364 * 24 * 60 * 60;
    return this.jwtService.sign(
      {
        sub: userId,
        phoneNumber,
        isAdmin: isAdmin ?? false, // ✅ Include isAdmin
      },
      { expiresIn: expiresIn },
    );
  }
}
