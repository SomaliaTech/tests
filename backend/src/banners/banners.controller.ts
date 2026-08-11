import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  ParseUUIDPipe,
  Query,
  DefaultValuePipe,
  ParseIntPipe,
  BadRequestException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiBody,
  ApiResponse,
  ApiQuery,
} from '@nestjs/swagger';
import { BannersService } from './banners.service';
import { CreateBannerDto } from './dto/create-banner.dto';
import { UpdateBannerDto } from './dto/update-banner.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
@ApiTags('banners')
@Controller('banners')
export class BannersController {
  constructor(private bannersService: BannersService) {}

  // ==========================================
  // ✅ STATIC ROUTES FIRST (before :id)
  // ==========================================

  @Get('active')
  @ApiOperation({ summary: 'Get all active banners (Public)' })
  async getActiveBanners() {
    return this.bannersService.getActiveBanners();
  }

  @Get('discounts')
  @ApiOperation({ summary: 'Get active discount banners (Public)' })
  async getActiveDiscountBanners() {
    return this.bannersService.getActiveDiscountBanners();
  }

  @Get('flash-sales')
  @ApiOperation({ summary: 'Get active flash sale banners (Public)' })
  async getActiveFlashSaleBanners() {
    return this.bannersService.getActiveFlashSaleBanners();
  }

  // ==========================================
  // ✅ UPLOAD ROUTE
  // ==========================================

  @Post('upload-image')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Upload banner image (Admin only)' })
  async uploadBannerImage(@Body() body: { image: string; fileName: string }) {
    return this.bannersService.uploadImage(body.image, body.fileName);
  }

  // ==========================================
  // ✅ ADMIN ROUTES
  // ==========================================

  @Get()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get all banners (Admin) - Paginated' })
  async getAllBanners(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('search') search?: string,
    @Query('isActive') isActive?: string,
    @Query('hasDiscount') hasDiscount?: string,
    @Query('isFlashSale') isFlashSale?: string,
  ) {
    const isActiveBool =
      isActive === 'true' ? true : isActive === 'false' ? false : undefined;
    const hasDiscountBool =
      hasDiscount === 'true'
        ? true
        : hasDiscount === 'false'
          ? false
          : undefined;
    const isFlashSaleBool =
      isFlashSale === 'true'
        ? true
        : isFlashSale === 'false'
          ? false
          : undefined;

    return this.bannersService.getAllBanners(
      page,
      limit,
      search,
      isActiveBool,
      hasDiscountBool,
      isFlashSaleBool,
    );
  }

  // ✅ DYNAMIC ROUTE LAST (after all static routes)
  @Get(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get banner by ID (Admin)' })
  async getBannerById(@Param('id', ParseUUIDPipe) id: string) {
    return this.bannersService.getBannerById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create banner (Admin only)' })
  async createBanner(@Request() req, @Body() createBannerDto: CreateBannerDto) {
    const userId = req.user.userId || req.user.sub;
    return this.bannersService.createBanner(createBannerDto, userId);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update banner (Admin only)' })
  async updateBanner(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateBannerDto: UpdateBannerDto,
  ) {
    return this.bannersService.updateBanner(id, updateBannerDto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Delete banner (Admin only)' })
  async deleteBanner(@Param('id', ParseUUIDPipe) id: string) {
    return this.bannersService.deleteBanner(id);
  }

  @Put(':id/toggle')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Toggle banner status (Admin only)' })
  async toggleBannerStatus(@Param('id', ParseUUIDPipe) id: string) {
    return this.bannersService.toggleBannerStatus(id);
  }

  @Put('reorder')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Reorder banners (Admin only)' })
  async reorderBanners(@Body('bannerIds') bannerIds: string[]) {
    if (!bannerIds || !Array.isArray(bannerIds) || bannerIds.length === 0) {
      throw new BadRequestException('bannerIds array is required');
    }
    return this.bannersService.reorderBanners(bannerIds);
  }
}
