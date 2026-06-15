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
import { AuthService } from './auth.service';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { CompleteProfileDto } from './dto/complete-profile.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { UploadProfileImageDto } from './dto/upload-profile-image.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('send-otp')
  async sendOtp(@Body() sendOtpDto: SendOtpDto) {
    return this.authService.sendOtp(sendOtpDto.phoneNumber);
  }

  @Post('verify-otp')
  async verifyOtp(@Body() verifyOtpDto: VerifyOtpDto) {
    return this.authService.verifyOtp(
      verifyOtpDto.phoneNumber,
      verifyOtpDto.otpCode,
    );
  }

  @Post('complete-profile')
  @UseGuards(JwtAuthGuard)
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

  // Used for standard multipart binary stream uploads
  @Post('upload-profile-image')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('image'))
  async uploadProfileImage(
    @Request() req,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }),
          new FileTypeValidator({ fileType: 'image/(jpeg|png|jpg|webp)' }),
        ],
        fileIsRequired: false, // Change to false
      }),
    )
    file?: Express.Multer.File,
  ) {
    if (!file) {
      // If no file, try to get from body
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
  // FIX TARGET: Flutter app now uses this endpoint for direct Base64 string uploading
  @Post('upload-profile-image-url')
  @UseGuards(JwtAuthGuard)
  async uploadProfileImageFromUrl(
    @Request() req,
    @Body() body: UploadProfileImageDto,
  ) {
    return this.authService.uploadProfileImage(req.user.userId, body.imageUrl);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMe(@Request() req) {
    return this.authService.getMe(req.user.userId);
  }

  @Patch('profile')
  @UseGuards(JwtAuthGuard)
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
