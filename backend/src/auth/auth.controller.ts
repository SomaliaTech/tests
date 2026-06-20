import {
  Controller,
  Post,
  Body,
  Get,
  UseGuards,
  Request,
  Patch,
  UploadedFile,
  UseInterceptors,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiBody,
  ApiConsumes,
} from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { CompleteProfileDto } from './dto/complete-profile.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { UploadProfileImageDto } from './dto/upload-profile-image.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('send-otp')
  @ApiOperation({
    summary: 'Send OTP to phone number',
    description:
      'Sends a one-time password to the provided phone number for authentication. In development, returns the OTP in the response for testing.',
  })
  @ApiBody({ type: SendOtpDto })
  @ApiResponse({
    status: 200,
    description: 'OTP sent successfully',
    schema: {
      example: {
        message: 'OTP sent successfully',
        debugOtp: '123456',
      },
    },
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid phone number format',
  })
  async sendOtp(@Body() sendOtpDto: SendOtpDto) {
    return this.authService.sendOtp(sendOtpDto.phoneNumber);
  }

  @Post('verify-otp')
  @ApiOperation({
    summary: 'Verify OTP code',
    description:
      'Verifies the OTP code and returns a JWT token for authenticated access.',
  })
  @ApiBody({ type: VerifyOtpDto })
  @ApiResponse({
    status: 200,
    description: 'OTP verified successfully',
    schema: {
      example: {
        message: 'OTP verified successfully',
        token: 'eyJhbGciOiJIUzI1NiIs...',
        user: {
          id: '550e8400-e29b-41d4-a716-446655440000',
          phoneNumber: '+252612345678',
          isVerified: true,
          hasProfile: false,
        },
      },
    },
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid OTP code or phone number',
  })
  async verifyOtp(@Body() verifyOtpDto: VerifyOtpDto) {
    return this.authService.verifyOtp(
      verifyOtpDto.phoneNumber,
      verifyOtpDto.otpCode,
    );
  }

  @Post('complete-profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Complete user profile',
    description:
      'Completes the user profile with name, email, and optional profile image URL.',
  })
  @ApiBody({ type: CompleteProfileDto })
  @ApiResponse({
    status: 200,
    description: 'Profile completed successfully',
    schema: {
      example: {
        message: 'Profile completed successfully',
        token: 'eyJhbGciOiJIUzI1NiIs...',
        user: {
          id: '550e8400-e29b-41d4-a716-446655440000',
          phoneNumber: '+252612345678',
          name: 'farah jamac',
          email: 'farah@example.com',
          profileImage: 'https://example.com/profile.jpg',
          hasProfile: true,
        },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - Invalid or missing JWT token',
  })
  async completeProfile(
    @Request() req,
    @Body() completeProfileDto: CompleteProfileDto,
  ) {
    const userId = req.user.userId;
    return this.authService.completeProfile(
      userId,
      completeProfileDto.name,
      completeProfileDto.email,
      completeProfileDto.profileImage,
    );
  }

  @Post('upload-profile-image')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('image'))
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Upload profile image (multipart)',
    description:
      'Uploads a profile image using multipart form data. Supports JPEG, PNG, JPG, and WEBP formats up to 5MB.',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        image: {
          type: 'string',
          format: 'binary',
          description: 'Profile image file (JPEG, PNG, JPG, WEBP)',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Profile image uploaded successfully',
    schema: {
      example: {
        message: 'Profile image uploaded successfully',
        profileImage: 'https://res.cloudinary.com/...',
      },
    },
  })
  @ApiResponse({
    status: 400,
    description: 'No image provided or invalid file format',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - Invalid or missing JWT token',
  })
  async uploadProfileImage(
    @Request() req,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }),
          new FileTypeValidator({ fileType: 'image/(jpeg|png|jpg|webp)' }),
        ],
        fileIsRequired: false,
      }),
    )
    file?: Express.Multer.File,
  ) {
    if (!file) {
      const { imageUrl } = req.body;
      if (imageUrl) {
        return this.authService.uploadProfileImage(req.user.userId, imageUrl);
      }
      throw new BadRequestException('No image provided');
    }

    const base64Image = file.buffer.toString('base64');
    const dataUri = `data:${file.mimetype};base64,${base64Image}`;

    return this.authService.uploadProfileImage(req.user.userId, dataUri);
  }

  @Post('upload-profile-image-url')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Upload profile image (Base64)',
    description:
      'Uploads a profile image using a Base64 encoded string. Recommended for Flutter apps.',
  })
  @ApiBody({ type: UploadProfileImageDto })
  @ApiResponse({
    status: 200,
    description: 'Profile image uploaded successfully',
    schema: {
      example: {
        message: 'Profile image uploaded successfully',
        profileImage: 'https://res.cloudinary.com/...',
      },
    },
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid image URL or format',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - Invalid or missing JWT token',
  })
  async uploadProfileImageFromUrl(
    @Request() req,
    @Body() body: UploadProfileImageDto,
  ) {
    return this.authService.uploadProfileImage(req.user.userId, body.imageUrl);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get current user',
    description: 'Returns the currently authenticated user information.',
  })
  @ApiResponse({
    status: 200,
    description: 'Current user information retrieved',
    schema: {
      example: {
        id: '550e8400-e29b-41d4-a716-446655440000',
        phoneNumber: '+252612345678',
        name: 'farah Jamac',
        email: 'farah@example.com',
        profileImage: 'https://example.com/profile.jpg',
        isVerified: true,
        hasProfile: true,
        marketId: '550e8400-e29b-41d4-a716-446655440001',
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - Invalid or missing JWT token',
  })
  async getMe(@Request() req) {
    return this.authService.getMe(req.user.userId);
  }

  @Patch('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update user profile',
    description:
      'Updates the user profile information. All fields are optional.',
  })
  @ApiBody({ type: UpdateProfileDto })
  @ApiResponse({
    status: 200,
    description: 'Profile updated successfully',
    schema: {
      example: {
        id: '550e8400-e29b-41d4-a716-446655440000',
        phoneNumber: '+252612345678',
        name: 'Farah jamac Updated',
        email: 'farah.updated@example.com',
        profileImage: 'https://example.com/profile.jpg',
        marketId: '550e8400-e29b-41d4-a716-446655440001',
      },
    },
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid input data',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - Invalid or missing JWT token',
  })
  async updateProfile(
    @Request() req,
    @Body() updateProfileDto: UpdateProfileDto,
  ) {
    return this.authService.updateProfile(
      req.user.userId,
      updateProfileDto.name,
      updateProfileDto.email,
      updateProfileDto.marketId,
    );
  }
}
