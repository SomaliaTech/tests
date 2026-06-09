import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { DrizzleService } from '../drizzle/drizzle.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { users } from '../drizzle/schema';
import { eq } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AuthService {
  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private drizzle: DrizzleService,
    private cloudinaryService: CloudinaryService,
  ) {}

  //   async sendOtp(phoneNumber: string) {
  //     // Clean phone number (remove spaces, etc.)
  //     const cleanedPhone = phoneNumber.trim();

  //     // Generate 6-digit OTP
  //     const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
  //     const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000);

  //     // Find or create user
  //     const existingUser = await this.drizzle.db
  //       .select()
  //       .from(users)
  //       .where(eq(users.phoneNumber, cleanedPhone))
  //       .limit(1);

  //     if (existingUser.length > 0) {
  //       await this.drizzle.db
  //         .update(users)
  //         .set({
  //           otpCode,
  //           otpExpiresAt,
  //           updatedAt: new Date(),
  //         })
  //         .where(eq(users.phoneNumber, cleanedPhone));
  //     } else {
  //       await this.drizzle.db.insert(users).values({
  //         id: uuidv4(),
  //         phoneNumber: cleanedPhone,
  //         otpCode,
  //         otpExpiresAt,
  //         isVerified: false,
  //       });
  //     }

  //     console.log(`OTP for ${cleanedPhone}: ${otpCode}`);

  //     return {
  //       message: 'OTP sent successfully',
  //       debugOtp: otpCode,
  //     };
  //   }

  async sendOtp(phoneNumber: string) {
    // 1. Normalize phone number to standard +25261XXXXXXXXX format
    let cleanedPhone = phoneNumber.trim().replace(/\s+/g, ''); // Remove all spaces

    // If user sent "61..." or "061...", prepend +252
    if (cleanedPhone.startsWith('61') || cleanedPhone.startsWith('061')) {
      cleanedPhone = '+252' + cleanedPhone.replace(/^0?/, '');
    }
    // If user sent "+25261..." or "25261...", ensure it starts with +
    else if (cleanedPhone.startsWith('25261')) {
      cleanedPhone = '+' + cleanedPhone;
    }
    // If already starts with +25261, keep as is
    else if (!cleanedPhone.startsWith('+25261')) {
      throw new BadRequestException('Invalid Somali phone number format');
    }

    // Generate 6-digit OTP
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000);

    // Find or create user using the NORMALIZED phone number
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
        phoneNumber: cleanedPhone, // Always store normalized format
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

    // Mark user as verified and clear OTP
    await this.drizzle.db
      .update(users)
      .set({
        isVerified: true,
        otpCode: null,
        otpExpiresAt: null,
        updatedAt: new Date(),
      })
      .where(eq(users.phoneNumber, phoneNumber));

    // Generate JWT token
    const token = this.generateToken(currentUser.id, phoneNumber);

    return {
      message: 'OTP verified successfully',
      token,
      user: {
        id: currentUser.id,
        phoneNumber: currentUser.phoneNumber,
        isVerified: true,
        hasProfile: !!currentUser.name,
        name: currentUser.name,
        email: currentUser.email,
        profileImage: currentUser.profileImage,
      },
    };
  }

  async uploadProfileImage(userId: string, base64Image: string) {
    try {
      // Upload to Cloudinary
      const result = await this.cloudinaryService.uploadBase64(
        base64Image,
        'users/profiles',
      );

      // Update user with profile image URL
      const [updatedUser] = await this.drizzle.db
        .update(users)
        .set({
          profileImage: result.secure_url,
          updatedAt: new Date(),
        })
        .where(eq(users.id, userId))
        .returning();

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
        },
      };
    } catch (error) {
      throw new Error(`Failed to upload profile image: ${error.message}`);
    }
  }

  async completeProfile(
    userId: string,
    name: string,
    email?: string,
    profileImageUrl?: string,
  ) {
    const updateData: any = {
      name,
      updatedAt: new Date(),
    };

    if (email) updateData.email = email;
    if (profileImageUrl) updateData.profileImage = profileImageUrl;

    const [updatedUser] = await this.drizzle.db
      .update(users)
      .set(updateData)
      .where(eq(users.id, userId))
      .returning();

    // Generate new token with updated info
    const token = this.generateToken(updatedUser.id, updatedUser.phoneNumber);

    return {
      message: 'Profile completed successfully',
      token,
      user: {
        id: updatedUser.id,
        phoneNumber: updatedUser.phoneNumber,
        name: updatedUser.name,
        email: updatedUser.email,
        profileImage: updatedUser.profileImage,
        isVerified: updatedUser.isVerified,
      },
    };
  }

  async getMe(userId: string) {
    const [user] = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId));

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    return {
      id: user.id,
      phoneNumber: user.phoneNumber,
      name: user.name,
      email: user.email,
      profileImage: user.profileImage,
      isVerified: user.isVerified,
    };
  }

  async updateProfile(userId: string, name?: string, email?: string) {
    const updateData: any = { updatedAt: new Date() };
    if (name) updateData.name = name;
    if (email) updateData.email = email;

    const [updatedUser] = await this.drizzle.db
      .update(users)
      .set(updateData)
      .where(eq(users.id, userId))
      .returning();

    return {
      message: 'Profile updated successfully',
      user: {
        id: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        phoneNumber: updatedUser.phoneNumber,
        profileImage: updatedUser.profileImage,
      },
    };
  }

  private generateToken(userId: string, phoneNumber: string): string {
    return this.jwtService.sign({
      sub: userId,
      phoneNumber,
    });
  }
}
