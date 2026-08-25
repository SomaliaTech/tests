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
  ApiBody,
  ApiConsumes,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { UploadProfileImageDto } from './dto/upload-profile-image.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { FacebookAuthDto } from './dto/facebook-auth.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('send-otp')
  @UseGuards(ThrottlerGuard)
  @Throttle({ otp: { limit: 3, ttl: 60000 } }) // 3 requests per minute
  @ApiOperation({ summary: 'Send OTP to phone number' })
  @ApiBody({ type: SendOtpDto })
  async sendOtp(@Body() sendOtpDto: SendOtpDto) {
    return this.authService.sendOtp(sendOtpDto.phoneNumber);
  }

  @Post('verify-otp')
  @UseGuards(ThrottlerGuard)
  @Throttle({ otp: { limit: 5, ttl: 60000 } }) // 5 requests per minute
  @ApiOperation({ summary: 'Verify OTP code' })
  @ApiBody({ type: VerifyOtpDto })
  async verifyOtp(@Body() verifyOtpDto: VerifyOtpDto) {
    return this.authService.verifyOtp(
      verifyOtpDto.phoneNumber,
      verifyOtpDto.otpCode,
    );
  }

  @Post('complete-profile')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ auth: { limit: 10, ttl: 60000 } })
  @UseInterceptors(FileInterceptor('profileImage'))
  @ApiBearerAuth('JWT-auth')
  async completeProfile(
    @Request() req,
    @Body() body: { name: string; marketId: string; profileImage?: string },
  ) {
    if (!body.name || !body.marketId) {
      throw new BadRequestException('Name and market are required');
    }
    return this.authService.completeProfile(req.user.userId, body);
  }

  @Post('google')
  @UseGuards(ThrottlerGuard)
  @Throttle({ auth: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Google Sign-In' })
  @ApiBody({ type: GoogleAuthDto })
  async googleSignIn(@Body() dto: GoogleAuthDto) {
    return this.authService.googleSignIn(dto);
  }

  @Post('facebook')
  @UseGuards(ThrottlerGuard)
  @Throttle({ auth: { limit: 5, ttl: 60000 } })
  async facebookSignIn(@Body() dto: FacebookAuthDto) {
    console.log('📘 Facebook endpoint called');
    console.log('📘 DTO:', dto);

    // ✅ Make sure to RETURN the result
    return await this.authService.facebookSignIn(dto);
  }
  @Post('upload-profile-image')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ auth: { limit: 5, ttl: 60000 } })
  @UseInterceptors(FileInterceptor('image'))
  @ApiBearerAuth('JWT-auth')
  @ApiConsumes('multipart/form-data')
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
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ auth: { limit: 5, ttl: 60000 } })
  @ApiBearerAuth('JWT-auth')
  @ApiBody({ type: UploadProfileImageDto })
  async uploadProfileImageFromUrl(
    @Request() req,
    @Body() body: UploadProfileImageDto,
  ) {
    return this.authService.uploadProfileImage(req.user.userId, body.imageUrl);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiBearerAuth('JWT-auth')
  async getMe(@Request() req) {
    return this.authService.getMe(req.user.userId);
  }

  @Patch('profile')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ auth: { limit: 10, ttl: 60000 } })
  @ApiBearerAuth('JWT-auth')
  @ApiBody({ type: UpdateProfileDto })
  async updateProfile(
    @Request() req,
    @Body() updateProfileDto: UpdateProfileDto,
  ) {
    return this.authService.updateProfile(
      req.user.userId,
      updateProfileDto.name,
      updateProfileDto.marketId,
    );
  }
}
