// src/admin/admin.controller.ts
import {
  Controller,
  Get,
  Put,
  Post,
  Delete,
  UseGuards,
  Query,
  Param,
  Body,
  UseInterceptors,
  UploadedFiles,
  Request,
  DefaultValuePipe,
  ParseIntPipe,
  ParseUUIDPipe,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { FileInterceptor, AnyFilesInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiParam,
  ApiBody,
  ApiConsumes,
  ApiResponse,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { SuperAdminGuard } from '../auth/guards/super-admin.guard';
import { PermissionGuard, Permissions } from '../auth/guards/permission.guard';
import { Permission } from './enums/permissions.enum';
import { CreateProductAdminDto } from './dto/create-proudct-admin-dto';
import { LogSanitizer } from '../common/utils/log-sanitizer.util';

@ApiTags('admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard, PermissionGuard, ThrottlerGuard)
@ApiBearerAuth('JWT-auth')
export class AdminController {
  private readonly logger = new Logger(AdminController.name);
  private readonly isProduction: boolean;

  constructor(private adminService: AdminService) {
    this.isProduction = process.env.NODE_ENV === 'production';
  }

  private logInfo(message: string, data?: any) {
    if (this.isProduction) return;
    const sanitizedData = data ? LogSanitizer.sanitize(data) : undefined;
    this.logger.log(message, sanitizedData);
  }

  // ==========================================
  // ✅ MY PERMISSIONS
  // ==========================================
  @Get('me/permissions')
  @Permissions()
  @ApiOperation({ summary: 'Get my own permissions (any admin)' })
  async getMyPermissions(@Request() req) {
    const permissions = await this.adminService.getUserPermissions(
      req.user.userId,
    );
    return { permissions };
  }

  // ==========================================
  // STATS
  // ==========================================
  @Get('stats')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get admin dashboard statistics' })
  getStats() {
    return this.adminService.getStats();
  }

  // ==========================================
  // ROLE MANAGEMENT
  // ==========================================
  @Get('roles')
  @Permissions(Permission.ADMIN_VIEW)
  @ApiOperation({ summary: 'Get all roles' })
  async getAllRoles() {
    return this.adminService.getAllRoles();
  }

  @Post('roles')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Permissions(Permission.ADMIN_CREATE)
  @ApiOperation({ summary: 'Create a new role' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        description: { type: 'string' },
        permissions: { type: 'array', items: { type: 'string' } },
      },
    },
  })
  async createRole(
    @Body() data: { name: string; description?: string; permissions: string[] },
  ) {
    return this.adminService.createRole(data);
  }

  @Put('roles/:roleId')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Permissions(Permission.ADMIN_UPDATE)
  @ApiOperation({ summary: 'Update a role' })
  @ApiParam({ name: 'roleId', description: 'Role UUID' })
  async updateRole(
    @Param('roleId', ParseUUIDPipe) roleId: string,
    @Body()
    data: { name?: string; description?: string; permissions?: string[] },
  ) {
    return this.adminService.updateRole(roleId, data);
  }

  @Delete('roles/:roleId')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Permissions(Permission.ADMIN_DELETE)
  @ApiOperation({ summary: 'Delete a role' })
  @ApiParam({ name: 'roleId', description: 'Role UUID' })
  async deleteRole(@Param('roleId', ParseUUIDPipe) roleId: string) {
    return this.adminService.deleteRole(roleId);
  }

  // ==========================================
  // USER ROLE ASSIGNMENT
  // ==========================================
  @Post('users/:userId/roles')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Permissions(Permission.ADMIN_UPDATE)
  @ApiOperation({ summary: 'Assign a role to a user' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  async assignRoleToUser(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body('roleId') roleId: string,
  ) {
    return this.adminService.assignRoleToUser(userId, roleId);
  }

  @Delete('users/:userId/roles/:roleId')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Permissions(Permission.ADMIN_UPDATE)
  @ApiOperation({ summary: 'Remove a role from a user' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  @ApiParam({ name: 'roleId', description: 'Role UUID' })
  async removeRoleFromUser(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Param('roleId', ParseUUIDPipe) roleId: string,
  ) {
    return this.adminService.removeRoleFromUser(userId, roleId);
  }

  @Get('users/:userId/roles')
  @Permissions(Permission.ADMIN_VIEW)
  @ApiOperation({ summary: 'Get user roles' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  async getUserRoles(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.adminService.getUserRoles(userId);
  }

  // ==========================================
  // USER PERMISSIONS
  // ==========================================
  @Get('users/:userId/permissions')
  @Permissions(Permission.ADMIN_VIEW)
  @ApiOperation({ summary: 'Get user permissions' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  async getUserPermissions(@Param('userId', ParseUUIDPipe) userId: string) {
    const permissions = await this.adminService.getUserPermissions(userId);
    return { permissions };
  }

  // ==========================================
  // DASHBOARD
  // ==========================================
  @Get('dashboard/all')
  @ApiOperation({ summary: 'Get all dashboard data in one request' })
  async getAllDashboardData(
    @Request() req,
    @Query('period') period: string = 'week',
  ) {
    return this.adminService.getAllDashboardData(req.user.userId, period);
  }

  @Get('dashboard/stats')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get dashboard statistics with period' })
  getDashboardStats(@Query('period') period: string = 'week') {
    return this.adminService.getDashboardStats(period);
  }

  @Get('dashboard/users-chart')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get users registration chart data' })
  getUsersChartData(@Query('period') period: string = 'week') {
    return this.adminService.getUsersChartData(period);
  }

  @Get('dashboard/revenue-chart')
  @Permissions(Permission.REVENUE_VIEW)
  @ApiOperation({ summary: 'Get revenue chart data' })
  getRevenueChart(@Query('period') period: string = 'week') {
    return this.adminService.getRevenueChart(period);
  }

  @Get('dashboard/device-traffic')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get device traffic distribution' })
  getDeviceTraffic() {
    return this.adminService.getDeviceTraffic();
  }

  @Get('dashboard/location-traffic')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get location traffic distribution' })
  getLocationTraffic() {
    return this.adminService.getLocationTraffic();
  }

  @Get('dashboard/product-traffic')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get product traffic' })
  getProductTraffic(@Query('period') period: string = 'week') {
    return this.adminService.getProductTraffic(period);
  }

  @Get('dashboard/recent-orders')
  @Permissions(Permission.ORDER_VIEW)
  @ApiOperation({ summary: 'Get recent orders' })
  getRecentOrders(
    @Query('limit', new DefaultValuePipe(5), ParseIntPipe) limit: number = 5,
  ) {
    return this.adminService.getRecentOrders(limit);
  }

  // ==========================================
  // REVENUE
  // ==========================================
  @Get('revenue/summary')
  @Permissions(Permission.REVENUE_VIEW)
  @ApiOperation({ summary: 'Get revenue summary with growth stats' })
  getRevenueSummary(@Query('period') period: string = 'week') {
    return this.adminService.getRevenueSummary(period);
  }

  @Get('revenue')
  @Permissions(Permission.REVENUE_VIEW)
  @ApiOperation({ summary: 'Get all revenue records with filters' })
  getAllRevenue(
    @Query('search') search?: string,
    @Query('paymentMethod') paymentMethod?: string,
    @Query('status') status?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ) {
    return this.adminService.getAllRevenue(
      search,
      paymentMethod,
      status,
      page,
      limit,
    );
  }

  @Get('revenue/:orderId')
  @Permissions(Permission.REVENUE_VIEW)
  @ApiOperation({ summary: 'Get revenue details by order ID' })
  @ApiParam({ name: 'orderId', description: 'Order UUID' })
  getRevenueById(@Param('orderId', ParseUUIDPipe) orderId: string) {
    return this.adminService.getRevenueById(orderId);
  }

  // ==========================================
  // ORDERS
  // ==========================================
  @Get('orders')
  @Permissions(Permission.ORDER_VIEW)
  @ApiOperation({ summary: 'Get all orders with pagination' })
  getAllOrders(
    @Query('search') search?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('status') status?: string,
  ) {
    return this.adminService.getAllOrders(search, page, limit, status);
  }

  @Put('orders/:orderId/status')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @Permissions(Permission.ORDER_UPDATE)
  @ApiOperation({ summary: 'Update order status (Admin only)' })
  @ApiParam({ name: 'orderId', description: 'Order UUID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        status: {
          type: 'string',
          enum: [
            'PENDING',
            'CONFIRMED',
            'PROCESSING',
            'SHIPPED',
            'DELIVERED',
            'CANCELLED',
          ],
        },
      },
    },
  })
  updateOrderStatus(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body('status') status: string,
  ) {
    return this.adminService.updateOrderStatus(orderId, status);
  }

  // ==========================================
  // USERS
  // ==========================================
  @Get('users')
  @Permissions(Permission.USER_VIEW)
  @ApiOperation({ summary: 'Get all users with pagination' })
  async getAllUsers(
    @Request() req,
    @Query('search') search?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ) {
    return this.adminService.getAllUsers(req.user.userId, search, page, limit);
  }

  @Get('users/:userId')
  @Permissions(Permission.USER_VIEW)
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  getUserById(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.adminService.getUserById(userId);
  }

  @Post('users')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Permissions(Permission.USER_CREATE)
  @ApiOperation({ summary: 'Create a new user' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        phoneNumber: { type: 'string', example: '+252612345678' },
        name: { type: 'string', example: 'John Doe' },
        email: { type: 'string', example: 'john@example.com' },
        marketId: {
          type: 'string',
          example: '550e8400-e29b-41d4-a716-446655440001',
        },
      },
      required: ['phoneNumber'],
    },
  })
  createUser(
    @Body()
    userData: {
      phoneNumber: string;
      name?: string;
      email?: string;
      marketId?: string;
    },
  ) {
    // Safe logging
    this.logInfo('Creating user', {
      phoneNumber: LogSanitizer.maskPhoneNumber(userData.phoneNumber),
    });
    return this.adminService.createUser(userData);
  }

  @Put('users/:userId')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @Permissions(Permission.USER_UPDATE)
  @ApiOperation({ summary: 'Update user' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  updateUser(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() updateData: { name?: string; email?: string; marketId?: string },
  ) {
    return this.adminService.updateUser(userId, updateData);
  }

  @Put('users/:userId/admin')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiOperation({ summary: 'Toggle admin status (Super Admin only)' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  updateAdminStatus(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() data: { isAdmin?: boolean; isSuperAdmin?: boolean },
  ) {
    return this.adminService.updateAdminStatus(userId, data);
  }

  @Delete('users/:userId')
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiOperation({ summary: 'Delete user (Super Admin only)' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  deleteUser(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.adminService.deleteUser(userId);
  }

  // ==========================================
  // COLORS
  // ==========================================
  @Get('colors/all')
  @Permissions(Permission.COLOR_VIEW)
  @ApiOperation({ summary: 'Get all colors' })
  getAllColors() {
    return this.adminService.getAllColors();
  }

  @Post('colors')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @Permissions(Permission.COLOR_CREATE)
  @ApiOperation({ summary: 'Create a new color' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'Red' },
        code: { type: 'string', example: '#FF0000' },
      },
      required: ['name', 'code'],
    },
  })
  createColor(@Body() data: { name: string; code: string }) {
    return this.adminService.createColor(data);
  }

  @Put('colors/:colorId')
  @Permissions(Permission.COLOR_UPDATE)
  @ApiOperation({ summary: 'Update color' })
  @ApiParam({ name: 'colorId', description: 'Color UUID' })
  updateColor(
    @Param('colorId', ParseUUIDPipe) colorId: string,
    @Body() data: { name?: string; code?: string },
  ) {
    return this.adminService.updateColor(colorId, data);
  }

  @Delete('colors/:colorId')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Permissions(Permission.COLOR_DELETE)
  @ApiOperation({ summary: 'Delete color' })
  @ApiParam({ name: 'colorId', description: 'Color UUID' })
  deleteColor(@Param('colorId', ParseUUIDPipe) colorId: string) {
    return this.adminService.deleteColor(colorId);
  }

  // ==========================================
  // SIZES
  // ==========================================
  @Get('sizes/all')
  @Permissions(Permission.SIZE_VIEW)
  @ApiOperation({ summary: 'Get all sizes' })
  getAllSizes() {
    return this.adminService.getAllSizes();
  }

  @Post('sizes')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @Permissions(Permission.SIZE_CREATE)
  @ApiOperation({ summary: 'Create a new size' })
  createSize(@Body() data: { name: string; value: string }) {
    return this.adminService.createSize(data);
  }

  @Put('sizes/:sizeId')
  @Permissions(Permission.SIZE_UPDATE)
  @ApiOperation({ summary: 'Update size' })
  @ApiParam({ name: 'sizeId', description: 'Size UUID' })
  updateSize(
    @Param('sizeId', ParseUUIDPipe) sizeId: string,
    @Body() data: { name?: string; value?: string },
  ) {
    return this.adminService.updateSize(sizeId, data);
  }

  @Delete('sizes/:sizeId')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Permissions(Permission.SIZE_DELETE)
  @ApiOperation({ summary: 'Delete size' })
  @ApiParam({ name: 'sizeId', description: 'Size UUID' })
  deleteSize(@Param('sizeId', ParseUUIDPipe) sizeId: string) {
    return this.adminService.deleteSize(sizeId);
  }

  // ==========================================
  // MARKETS
  // ==========================================
  @Get('markets/all')
  @Permissions(Permission.MARKET_VIEW)
  @ApiOperation({ summary: 'Get all markets with user count' })
  getAllMarkets(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
  ) {
    return this.adminService.getAllMarkets(page, limit);
  }

  @Post('markets')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Permissions(Permission.MARKET_CREATE)
  @ApiOperation({ summary: 'Create a new market' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'Hodon Market' },
        slug: { type: 'string', example: 'hodon-market' },
        city: { type: 'string', example: 'Mogadishu' },
        deliveryPrice: { type: 'number', example: 10.0 },
        freeDeliveryMinQuantity: { type: 'number', example: 5 },
        deliveryEstimationMinutes: { type: 'number', example: 90 },
      },
      required: ['name', 'deliveryPrice'],
    },
  })
  createMarket(
    @Body()
    data: {
      name: string;
      slug?: string;
      city?: string;
      deliveryPrice: number;
      freeDeliveryMinQuantity?: number;
      deliveryEstimationMinutes?: number;
    },
  ) {
    return this.adminService.createMarket(data);
  }

  @Put('markets/:marketId')
  @Permissions(Permission.MARKET_UPDATE)
  @ApiOperation({ summary: 'Update market' })
  @ApiParam({ name: 'marketId', description: 'Market UUID' })
  updateMarket(
    @Param('marketId', ParseUUIDPipe) marketId: string,
    @Body()
    data: {
      name?: string;
      slug?: string;
      city?: string;
      isActive?: boolean;
      deliveryPrice?: number;
      freeDeliveryMinQuantity?: number;
      deliveryEstimationMinutes?: number;
    },
  ) {
    return this.adminService.updateMarket(marketId, data);
  }

  @Put('markets/:marketId/deactivate')
  @Permissions(Permission.MARKET_UPDATE)
  @ApiOperation({ summary: 'Deactivate market (for markets with users)' })
  @ApiParam({ name: 'marketId', description: 'Market UUID' })
  deactivateMarket(@Param('marketId', ParseUUIDPipe) marketId: string) {
    return this.adminService.deactivateMarket(marketId);
  }

  @Delete('markets/:marketId')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Permissions(Permission.MARKET_DELETE)
  @ApiOperation({ summary: 'Delete market (only if no users)' })
  @ApiParam({ name: 'marketId', description: 'Market UUID' })
  deleteMarket(@Param('marketId', ParseUUIDPipe) marketId: string) {
    return this.adminService.deleteMarket(marketId);
  }

  // ==========================================
  // ENHANCED ANALYTICS
  // ==========================================
  @Get('analytics/enhanced')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get enhanced analytics with date range' })
  @ApiQuery({ name: 'startDate', required: true, type: String })
  @ApiQuery({ name: 'endDate', required: true, type: String })
  getEnhancedAnalytics(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.adminService.getEnhancedAnalytics(startDate, endDate);
  }

  @Get('revenue/by-date-range')
  @Permissions(Permission.REVENUE_VIEW)
  @ApiOperation({ summary: 'Get revenue by date range' })
  @ApiQuery({ name: 'startDate', required: true, type: String })
  @ApiQuery({ name: 'endDate', required: true, type: String })
  @ApiQuery({
    name: 'granularity',
    required: false,
    enum: ['day', 'week', 'month'],
  })
  getRevenueByDateRange(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
    @Query('granularity') granularity: 'day' | 'week' | 'month' = 'day',
  ) {
    return this.adminService.getRevenueByDateRange(
      startDate,
      endDate,
      granularity,
    );
  }

  @Get('analytics/custom-dates')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get analytics for specific dates' })
  @ApiQuery({ name: 'dates', required: true, type: String })
  async getAnalyticsForCustomDates(@Query('dates') datesString: string) {
    try {
      const dates = datesString.split(',').map((d) => new Date(d));
      const invalidDates = dates.filter((d) => isNaN(d.getTime()));
      if (invalidDates.length > 0) {
        throw new BadRequestException('Invalid date format');
      }
      return this.adminService.getAnalyticsForCustomDates(dates);
    } catch (error) {
      throw new BadRequestException('Error parsing dates');
    }
  }

  @Get('revenue/custom-dates')
  @Permissions(Permission.REVENUE_VIEW)
  @ApiOperation({ summary: 'Get revenue data for specific dates' })
  @ApiQuery({ name: 'dates', required: true, type: String })
  async getRevenueForCustomDates(@Query('dates') datesString: string) {
    try {
      const dates = datesString.split(',').map((d) => new Date(d));
      const invalidDates = dates.filter((d) => isNaN(d.getTime()));
      if (invalidDates.length > 0) {
        throw new BadRequestException('Invalid date format');
      }
      return this.adminService.getRevenueForCustomDates(dates);
    } catch (error) {
      throw new BadRequestException('Error parsing dates');
    }
  }

  // ==========================================
  // PRODUCTS
  // ==========================================
  @Get('products/list')
  @Permissions(Permission.PRODUCT_VIEW)
  @ApiOperation({ summary: 'Get ALL products without pagination' })
  getAllProductsList() {
    return this.adminService.getAllProducts();
  }

  @Get('products/all')
  @Permissions(Permission.PRODUCT_VIEW)
  @ApiOperation({ summary: 'Get all products for admin (paginated)' })
  getAllProductsAdmin(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('search') search?: string,
    @Query('categoryId') categoryId?: string,
  ) {
    return this.adminService.getAllProductsAdmin(
      page,
      limit,
      search,
      categoryId,
    );
  }

  @Get('products/:productId')
  @Permissions(Permission.PRODUCT_VIEW)
  @ApiOperation({ summary: 'Get product details for admin' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  getProductById(@Param('productId', ParseUUIDPipe) productId: string) {
    return this.adminService.getProductById(productId);
  }

  @Post('products')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Permissions(Permission.PRODUCT_CREATE)
  @ApiOperation({ summary: 'Create a new product with images and variants' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(AnyFilesInterceptor())
  async createProduct(
    @Body() body: any,
    @UploadedFiles() files?: Array<Express.Multer.File>,
  ) {
    let createProductDto: any = {};

    if (body?.data) {
      try {
        createProductDto = JSON.parse(body.data);
      } catch {
        createProductDto = body.data;
      }
    } else {
      createProductDto = body;
    }

    // Safe logging
    this.logInfo('Creating product', {
      productName: createProductDto?.name,
      categoryId: createProductDto?.categoryId,
      hasPrice: !!createProductDto?.price,
      fileCount: files?.length || 0,
    });

    const product = await this.adminService.createProduct(createProductDto);

    if (files && files.length > 0) {
      await this.adminService.uploadProductImages(product.id, files);
    }

    return this.adminService.getProductById(product.id);
  }

  @Put('products/:productId')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @Permissions(Permission.PRODUCT_UPDATE)
  @ApiOperation({ summary: 'Update product with variants and images' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(AnyFilesInterceptor())
  async updateProduct(
    @Param('productId', ParseUUIDPipe) productId: string,
    @Body() body: any,
    @UploadedFiles() files?: Array<Express.Multer.File>,
  ) {
    let updateData: any = {};

    if (body?.data) {
      try {
        updateData = JSON.parse(body.data);
      } catch {
        updateData = body.data;
      }
    } else {
      updateData = body;
    }

    // Safe logging
    this.logInfo('Updating product', {
      productId,
      keys: Object.keys(updateData),
      fileCount: files?.length || 0,
    });

    return this.adminService.updateProduct(productId, updateData, files || []);
  }

  @Delete('products/:productId')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Permissions(Permission.PRODUCT_DELETE)
  @ApiOperation({ summary: 'Delete product' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  deleteProduct(@Param('productId', ParseUUIDPipe) productId: string) {
    return this.adminService.deleteProduct(productId);
  }

  @Post('products/:productId/images')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @Permissions(Permission.PRODUCT_UPDATE)
  @ApiOperation({ summary: 'Upload product images' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('images', { limits: { fileSize: 5 * 1024 * 1024 } }),
  )
  uploadProductImages(
    @Param('productId', ParseUUIDPipe) productId: string,
    @UploadedFiles() images: Express.Multer.File[],
  ) {
    return this.adminService.uploadProductImages(productId, images);
  }

  // ==========================================
  // ANALYTICS ENDPOINTS
  // ==========================================
  @Get('analytics/all')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get all analytics data' })
  getAllAnalytics(@Query('period') period: string = 'week') {
    return this.adminService.getAllAnalytics(period);
  }

  @Get('analytics/top-products')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get top selling products' })
  getTopSellingProducts(
    @Query('limit', new DefaultValuePipe(5), ParseIntPipe) limit: number = 5,
    @Query('period') period: string = 'week',
  ) {
    return this.adminService.getTopSellingProducts(limit, period);
  }

  @Get('analytics/revenue-by-category')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get revenue breakdown by category' })
  getRevenueByCategory(@Query('period') period: string = 'week') {
    return this.adminService.getRevenueByCategory(period);
  }

  @Get('analytics/order-status')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get order status distribution' })
  getOrderStatusDistribution(@Query('period') period: string = 'week') {
    return this.adminService.getOrderStatusDistribution(period);
  }

  @Get('analytics/low-stock')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get low stock products' })
  getLowStockProducts(
    @Query('threshold', new DefaultValuePipe(5), ParseIntPipe)
    threshold: number = 5,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number = 10,
  ) {
    return this.adminService.getLowStockProducts(threshold, limit);
  }

  @Get('analytics/recent-signups')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get recent user signups' })
  getRecentSignups(
    @Query('limit', new DefaultValuePipe(5), ParseIntPipe) limit: number = 5,
  ) {
    return this.adminService.getRecentSignups(limit);
  }

  // ==========================================
  // CATEGORIES
  // ==========================================
  @Get('categories/tree')
  @Permissions(Permission.CATEGORY_VIEW)
  @ApiOperation({ summary: 'Get categories as tree structure' })
  getCategoriesTree() {
    return this.adminService.getCategoriesTree();
  }

  @Post('categories')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @Permissions(Permission.CATEGORY_CREATE)
  @ApiOperation({ summary: 'Create a new category' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'Electronics' },
        slug: { type: 'string', example: 'electronics' },
        description: { type: 'string', example: 'Electronic devices' },
        parentId: {
          type: 'string',
          example: '550e8400-e29b-41d4-a716-446655440000',
        },
      },
      required: ['name'],
    },
  })
  createCategory(
    @Body()
    data: {
      name: string;
      slug?: string;
      description?: string;
      parentId?: string;
    },
  ) {
    return this.adminService.createCategory(data);
  }

  @Put('categories/:categoryId')
  @Permissions(Permission.CATEGORY_UPDATE)
  @ApiOperation({ summary: 'Update category' })
  @ApiParam({ name: 'categoryId', description: 'Category UUID' })
  updateCategory(
    @Param('categoryId', ParseUUIDPipe) categoryId: string,
    @Body() data: { name?: string; slug?: string; description?: string },
  ) {
    return this.adminService.updateCategory(categoryId, data);
  }

  @Delete('categories/:categoryId')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Permissions(Permission.CATEGORY_DELETE)
  @ApiOperation({ summary: 'Delete category with optional product transfer' })
  @ApiParam({ name: 'categoryId', description: 'Category UUID' })
  @ApiQuery({ name: 'transferToId', required: false })
  deleteCategory(
    @Param('categoryId', ParseUUIDPipe) categoryId: string,
    @Query('transferToId') transferToId?: string,
  ) {
    return this.adminService.deleteCategory(categoryId, transferToId);
  }
}
