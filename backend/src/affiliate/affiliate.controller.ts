import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  ParseUUIDPipe,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiParam,
  ApiBody,
  ApiResponse,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AffiliateService } from './affiliate.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SuperAdminGuard } from '../auth/guards/super-admin.guard';
import {
  ApplyAffiliateDto,
  CreatePromoCodeDto,
  ReviewAffiliateRequestDto,
  RejectAffiliateRequestDto,
  UpdateAffiliateDto,
  UpdatePromoCodeDto,
  PayCommissionDto,
  ValidatePromoCodeDto,
} from './dto/affiliate.dto';
import { UpdateAffiliateSettingsDto } from './dto/affiliate-settings.dto';

@ApiTags('affiliate')
@Controller()
export class AffiliateController {
  constructor(private readonly affiliateService: AffiliateService) {}

  // ==========================================
  // USER ENDPOINTS (Authenticated)
  // ==========================================

  @Post('affiliate/apply')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 3, ttl: 86400000 } }) // 3 per day
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Apply to become an affiliate marketer' })
  @ApiBody({ type: ApplyAffiliateDto })
  async applyForAffiliate(@Request() req, @Body() dto: ApplyAffiliateDto) {
    return this.affiliateService.applyForAffiliate(req.user.userId, dto);
  }

  @Get('affiliate/my-status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get my affiliate application status' })
  async getMyStatus(@Request() req) {
    return this.affiliateService.getMyStatus(req.user.userId);
  }

  @Get('affiliate/my-stats')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get my affiliate statistics & dashboard' })
  async getMyStats(@Request() req) {
    // ✅ FIX: Call getMyAffiliateStats instead of getMyStats
    return this.affiliateService.getMyAffiliateStats(req.user.userId);
  }
  @Delete('admin/promo-codes/:id')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Delete a promo code' })
  @ApiParam({ name: 'id', type: String })
  async deletePromoCodeByAdmin(@Param('id', ParseUUIDPipe) id: string) {
    return this.affiliateService.deletePromoCodeByAdmin(id);
  }
  @Post('affiliate/promo-codes')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create a promo code (affiliate only)' })
  @ApiBody({ type: CreatePromoCodeDto })
  async createPromoCode(@Request() req, @Body() dto: CreatePromoCodeDto) {
    // ✅ FIXED: Swapped arguments to match the service signature (dto first, userId second)
    return this.affiliateService.createPromoCode(dto, req.user.userId);
  }

  @Get('affiliate/promo-codes')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get my promo codes' })
  async getMyPromoCodes(@Request() req) {
    return this.affiliateService.getMyPromoCodes(req.user.userId);
  }

  @Patch('affiliate/promo-codes/:id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update my promo code' })
  async updateMyPromoCode(
    @Request() req,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePromoCodeDto,
  ) {
    return this.affiliateService.updateMyPromoCode(req.user.userId, id, dto);
  }

  @Delete('affiliate/promo-codes/:id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Delete my promo code' })
  async deleteMyPromoCode(
    @Request() req,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.affiliateService.deleteMyPromoCode(req.user.userId, id);
  }

  @Get('admin/affiliate/settings')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Get affiliate program settings' })
  async getAffiliateSettings() {
    return this.affiliateService.getAffiliateSettings();
  }

  @Patch('admin/affiliate/settings')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: '👑 Super Admin: Update affiliate program settings',
  })
  @ApiBody({ type: UpdateAffiliateSettingsDto })
  async updateAffiliateSettings(@Body() dto: UpdateAffiliateSettingsDto) {
    return this.affiliateService.updateAffiliateSettings(dto);
  }
  // ==========================================
  // PUBLIC: Validate Promo Code
  // ==========================================

  @Post('affiliate/promo-codes/validate') // ✅ FIXED: Added 'affiliate/' prefix
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Validate a promo code during checkout' })
  @ApiBody({ type: ValidatePromoCodeDto })
  async validatePromoCode(@Request() req, @Body() dto: ValidatePromoCodeDto) {
    console.log('🎟️ [Validate] Request received:', dto);
    console.log('🎟️ [Validate] User ID:', req.user?.userId);

    const result = await this.affiliateService.validatePromoCode(
      dto.code,
      dto.orderAmount,
      req.user.userId,
    );

    console.log('🎟️ [Validate] Result:', result);
    return result;
  }

  // ==========================================
  // SUPER ADMIN ENDPOINTS
  // ==========================================

  @Get('admin/affiliate/dashboard')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Get affiliate dashboard' })
  async getAffiliateDashboard() {
    return this.affiliateService.getAffiliateDashboard();
  }

  @Get('admin/affiliate/requests')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Get all affiliate requests' })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['PENDING', 'APPROVED', 'REJECTED'],
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getAffiliateRequests(
    @Query('status') status?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ) {
    return this.affiliateService.getAffiliateRequests(status, page, limit);
  }

  @Post('admin/affiliate/requests/:id/approve')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Approve affiliate request' })
  @ApiBody({ type: ReviewAffiliateRequestDto })
  async approveRequest(
    @Request() req,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewAffiliateRequestDto,
  ) {
    return this.affiliateService.approveAffiliateRequest(
      id,
      req.user.userId,
      dto,
    );
  }

  @Post('admin/affiliate/requests/:id/reject')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Reject affiliate request' })
  @ApiBody({ type: RejectAffiliateRequestDto })
  async rejectRequest(
    @Request() req,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RejectAffiliateRequestDto,
  ) {
    return this.affiliateService.rejectAffiliateRequest(
      id,
      req.user.userId,
      dto,
    );
  }

  @Get('admin/affiliate/all')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Get all affiliates' })
  @ApiQuery({ name: 'status', required: false, enum: ['ACTIVE', 'SUSPENDED'] })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getAllAffiliates(
    @Query('status') status?: string,
    @Query('search') search?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ) {
    return this.affiliateService.getAllAffiliates(status, search, page, limit);
  }

  @Get('admin/affiliate/:id')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: '👑 Super Admin: Get affiliate detail with full stats',
  })
  async getAffiliateDetail(@Param('id', ParseUUIDPipe) id: string) {
    return this.affiliateService.getAffiliateDetail(id);
  }

  @Patch('admin/affiliate/:id')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Update affiliate (rate, status)' })
  async updateAffiliate(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAffiliateDto,
  ) {
    return this.affiliateService.updateAffiliate(id, dto);
  }

  @Get('affiliate/commissions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get my affiliate commissions' })
  @ApiQuery({ name: 'status', required: false })
  async getMyCommissions(@Request() req, @Query('status') status?: string) {
    return this.affiliateService.getMyCommissions(req.user.userId, status);
  }

  @Get('admin/affiliate/commissions/all')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Get all commissions' })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['PENDING', 'PAID', 'CANCELLED'],
  })
  @ApiQuery({ name: 'affiliateId', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getAllCommissions(
    @Query('status') status?: string,
    @Query('affiliateId') affiliateId?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
  ) {
    return this.affiliateService.getAllCommissions(
      status,
      affiliateId,
      page,
      limit,
    );
  }

  @Post('admin/affiliate/commissions/pay')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Mark commissions as paid' })
  @ApiBody({ type: PayCommissionDto })
  async payCommissions(@Body() dto: PayCommissionDto) {
    return this.affiliateService.payCommissions(dto);
  }

  // ==========================================
  // SUPER ADMIN: Promo Codes Management
  // ==========================================

  @Post('admin/promo-codes')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Create system-wide promo code' })
  @ApiBody({ type: CreatePromoCodeDto })
  async createSystemPromoCode(@Body() dto: CreatePromoCodeDto) {
    return this.affiliateService.createSystemPromoCode(dto);
  }

  // ==========================================
  // SUPER ADMIN: Approve / Edit Promo Code
  // ==========================================
  @Patch('admin/promo-codes/:id')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Approve / Update a promo code' })
  @ApiParam({ name: 'id', type: String })
  @ApiBody({ type: UpdatePromoCodeDto })
  async updatePromoCodeByAdmin(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePromoCodeDto,
  ) {
    return this.affiliateService.updatePromoCodeByAdmin(id, dto);
  }
  @Get('admin/promo-codes/all')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Get all promo codes' })
  @ApiQuery({ name: 'type', required: false, enum: ['system', 'affiliate'] })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getAllPromoCodes(
    @Query('type') type?: 'system' | 'affiliate',
    @Query('isActive') isActive?: boolean,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
  ) {
    return this.affiliateService.getAllPromoCodes(type, isActive, page, limit);
  }
}
