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
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiParam,
  ApiBody,
  ApiConsumes,
} from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CreateProductAdminDto,
  UpdateProductAdminDto,
} from './dto/create-proudct-admin-dto';
import { AdminGuard } from '../auth/guards/admin.guard';
import { SuperAdminGuard } from '../auth/guards/super-admin.guard';
import {
  FileFieldsInterceptor,
  AnyFilesInterceptor,
} from '@nestjs/platform-express';
@ApiTags('admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
@ApiBearerAuth('JWT-auth')
export class AdminController {
  constructor(private adminService: AdminService) {}

  // ==========================================
  // STATS
  // ==========================================
  @Get('stats')
  @ApiOperation({ summary: 'Get admin dashboard statistics' })
  getStats() {
    return this.adminService.getStats();
  }

  // ==========================================
  // DASHBOARD
  // ==========================================
  @Get('dashboard/all')
  @ApiOperation({
    summary: 'Get all dashboard data in one request (Optimized)',
  })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  async getAllDashboardData(@Query('period') period: string = 'week') {
    return this.adminService.getAllDashboardData(period);
  }

  @Get('dashboard/stats')
  @ApiOperation({ summary: 'Get dashboard statistics with period' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  getDashboardStats(@Query('period') period: string = 'week') {
    return this.adminService.getDashboardStats(period);
  }

  @Get('dashboard/users-chart')
  @ApiOperation({ summary: 'Get users registration chart data' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  getUsersChartData(@Query('period') period: string = 'week') {
    return this.adminService.getUsersChartData(period);
  }

  @Get('dashboard/revenue-chart')
  @ApiOperation({ summary: 'Get revenue chart data' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  getRevenueChart(@Query('period') period: string = 'week') {
    return this.adminService.getRevenueChart(period);
  }

  @Get('dashboard/device-traffic')
  @ApiOperation({ summary: 'Get device traffic distribution' })
  getDeviceTraffic() {
    return this.adminService.getDeviceTraffic();
  }

  @Get('dashboard/location-traffic')
  @ApiOperation({ summary: 'Get location traffic distribution' })
  getLocationTraffic() {
    return this.adminService.getLocationTraffic();
  }

  @Get('dashboard/product-traffic')
  @ApiOperation({ summary: 'Get product traffic' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  getProductTraffic(@Query('period') period: string = 'week') {
    return this.adminService.getProductTraffic(period);
  }

  @Get('dashboard/recent-orders')
  @ApiOperation({ summary: 'Get recent orders' })
  @ApiQuery({ name: 'limit', required: false })
  getRecentOrders(
    @Query('limit', new DefaultValuePipe(5), ParseIntPipe) limit: number = 5,
  ) {
    return this.adminService.getRecentOrders(limit);
  }

  // ==========================================
  // REVENUE
  // ==========================================
  @Get('revenue/summary')
  @ApiOperation({ summary: 'Get revenue summary with growth stats' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  getRevenueSummary(@Query('period') period: string = 'week') {
    return this.adminService.getRevenueSummary(period);
  }

  @Get('revenue')
  @ApiOperation({ summary: 'Get all revenue records with filters' })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'paymentMethod', required: false })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
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
  @ApiOperation({ summary: 'Get revenue details by order ID' })
  @ApiParam({ name: 'orderId', description: 'Order UUID' })
  getRevenueById(@Param('orderId', ParseUUIDPipe) orderId: string) {
    return this.adminService.getRevenueById(orderId);
  }

  // ==========================================
  // ORDERS - ✅ PAGINATED
  // ==========================================
  @Get('orders')
  @ApiOperation({ summary: 'Get all orders with pagination' })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false })
  getAllOrders(
    @Query('search') search?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('status') status?: string,
  ) {
    return this.adminService.getAllOrders(search, page, limit, status);
  }

  @Put('orders/:orderId/status')
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
  // USERS - ✅ PAGINATED
  // ==========================================
  @Get('users')
  @ApiOperation({ summary: 'Get all users with pagination' })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getAllUsers(
    @Request() req,
    @Query('search') search?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ) {
    return this.adminService.getAllUsers(req.user.userId, search, page, limit);
  }

  @Get('users/:userId')
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  getUserById(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.adminService.getUserById(userId);
  }

  @Post('users')
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
    return this.adminService.createUser(userData);
  }

  @Put('users/:userId')
  @ApiOperation({ summary: 'Update user' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        email: { type: 'string' },
        marketId: { type: 'string' },
      },
    },
  })
  updateUser(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() updateData: { name?: string; email?: string; marketId?: string },
  ) {
    return this.adminService.updateUser(userId, updateData);
  }

  @Put('users/:userId/admin')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiOperation({ summary: 'Toggle admin status (Super Admin only)' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        isAdmin: { type: 'boolean' },
        isSuperAdmin: { type: 'boolean' },
      },
    },
  })
  updateAdminStatus(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() data: { isAdmin?: boolean; isSuperAdmin?: boolean },
  ) {
    return this.adminService.updateAdminStatus(userId, data);
  }

  @Delete('users/:userId')
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
  @ApiOperation({ summary: 'Get all colors' })
  getAllColors() {
    return this.adminService.getAllColors();
  }

  @Post('colors')
  @ApiOperation({ summary: 'Create a new color' })
  createColor(@Body() data: { name: string; code: string }) {
    return this.adminService.createColor(data);
  }

  @Put('colors/:colorId')
  @ApiOperation({ summary: 'Update color' })
  updateColor(
    @Param('colorId', ParseUUIDPipe) colorId: string,
    @Body() data: { name?: string; code?: string },
  ) {
    return this.adminService.updateColor(colorId, data);
  }

  @Delete('colors/:colorId')
  @ApiOperation({ summary: 'Delete color' })
  deleteColor(@Param('colorId', ParseUUIDPipe) colorId: string) {
    return this.adminService.deleteColor(colorId);
  }

  // ==========================================
  // SIZES
  // ==========================================
  @Get('sizes/all')
  @ApiOperation({ summary: 'Get all sizes' })
  getAllSizes() {
    return this.adminService.getAllSizes();
  }

  @Post('sizes')
  @ApiOperation({ summary: 'Create a new size' })
  createSize(@Body() data: { name: string; value: string }) {
    return this.adminService.createSize(data);
  }

  @Put('sizes/:sizeId')
  @ApiOperation({ summary: 'Update size' })
  updateSize(
    @Param('sizeId', ParseUUIDPipe) sizeId: string,
    @Body() data: { name?: string; value?: string },
  ) {
    return this.adminService.updateSize(sizeId, data);
  }

  @Delete('sizes/:sizeId')
  @ApiOperation({ summary: 'Delete size' })
  deleteSize(@Param('sizeId', ParseUUIDPipe) sizeId: string) {
    return this.adminService.deleteSize(sizeId);
  }

  // ==========================================
  // MARKETS - ✅ PAGINATED
  // ==========================================

  // ==========================================
  // MARKETS - ✅ PAGINATED
  // ==========================================
  @Get('markets/all')
  @ApiOperation({ summary: 'Get all markets with user count' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  getAllMarkets(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
  ) {
    return this.adminService.getAllMarkets(page, limit);
  }

  @Post('markets')
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
      deliveryPrice: number; // ✅ REQUIRED
      freeDeliveryMinQuantity?: number; // ✅ OPTIONAL
      deliveryEstimationMinutes?: number; // ✅ OPTIONAL
    },
  ) {
    return this.adminService.createMarket(data);
  }

  @Put('markets/:marketId')
  @ApiOperation({ summary: 'Update market' })
  @ApiParam({ name: 'marketId', description: 'Market UUID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        slug: { type: 'string' },
        city: { type: 'string' },
        isActive: { type: 'boolean' },
        deliveryPrice: { type: 'number' },
        freeDeliveryMinQuantity: { type: 'number' },
        deliveryEstimationMinutes: { type: 'number' },
      },
    },
  })
  updateMarket(
    @Param('marketId', ParseUUIDPipe) marketId: string,
    @Body()
    data: {
      name?: string;
      slug?: string;
      city?: string;
      isActive?: boolean;
      deliveryPrice?: number; // ✅ NEW
      freeDeliveryMinQuantity?: number; // ✅ NEW
      deliveryEstimationMinutes?: number; // ✅ NEW
    },
  ) {
    return this.adminService.updateMarket(marketId, data);
  }

  @Put('markets/:marketId/deactivate')
  @ApiOperation({ summary: 'Deactivate market (for markets with users)' })
  @ApiParam({ name: 'marketId', description: 'Market UUID' })
  deactivateMarket(@Param('marketId', ParseUUIDPipe) marketId: string) {
    return this.adminService.deactivateMarket(marketId);
  }

  @Delete('markets/:marketId')
  @ApiOperation({ summary: 'Delete market (only if no users)' })
  @ApiParam({ name: 'marketId', description: 'Market UUID' })
  deleteMarket(@Param('marketId', ParseUUIDPipe) marketId: string) {
    return this.adminService.deleteMarket(marketId);
  }

  // Add to admin.controller.ts

  @Get('analytics/enhanced')
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

  // Add to admin.controller.ts

  @Get('analytics/custom-dates')
  @ApiOperation({
    summary: 'Get analytics for specific dates',
    description: 'Allows selecting individual days for analytics',
  })
  @ApiQuery({
    name: 'dates',
    required: true,
    type: String,
    description: 'Comma-separated ISO date strings (YYYY-MM-DD)',
  })
  async getAnalyticsForCustomDates(@Query('dates') datesString: string) {
    try {
      const dates = datesString.split(',').map((d) => new Date(d));

      // Validate dates
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
  @ApiOperation({
    summary: 'Get revenue data for specific dates',
    description: 'Revenue breakdown for selected individual days',
  })
  @ApiQuery({
    name: 'dates',
    required: true,
    type: String,
    description: 'Comma-separated ISO date strings (YYYY-MM-DD)',
  })
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
  // PRODUCTS - ✅ GET ALL (No Pagination)
  // ==========================================
  @Get('products/list')
  @ApiOperation({
    summary: 'Get ALL products without pagination',
    description: 'Returns all products for admin management',
  })
  getAllProductsList() {
    return this.adminService.getAllProducts();
  }

  // Add these endpoints to your AdminController class

  // ==========================================
  // ANALYTICS ENDPOINTS
  // ==========================================
  @Get('analytics/all')
  @ApiOperation({
    summary: 'Get all analytics data',
    description:
      'Returns top products, revenue by category, order status, low stock, and recent signups',
  })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  getAllAnalytics(@Query('period') period: string = 'week') {
    return this.adminService.getAllAnalytics(period);
  }

  @Get('analytics/top-products')
  @ApiOperation({ summary: 'Get top selling products' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  getTopSellingProducts(
    @Query('limit', new DefaultValuePipe(5), ParseIntPipe) limit: number = 5,
    @Query('period') period: string = 'week',
  ) {
    return this.adminService.getTopSellingProducts(limit, period);
  }

  @Get('analytics/revenue-by-category')
  @ApiOperation({ summary: 'Get revenue breakdown by category' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  getRevenueByCategory(@Query('period') period: string = 'week') {
    return this.adminService.getRevenueByCategory(period);
  }

  @Get('analytics/order-status')
  @ApiOperation({ summary: 'Get order status distribution' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  getOrderStatusDistribution(@Query('period') period: string = 'week') {
    return this.adminService.getOrderStatusDistribution(period);
  }

  @Get('analytics/low-stock')
  @ApiOperation({ summary: 'Get low stock products' })
  @ApiQuery({ name: 'threshold', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  getLowStockProducts(
    @Query('threshold', new DefaultValuePipe(5), ParseIntPipe)
    threshold: number = 5,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number = 10,
  ) {
    return this.adminService.getLowStockProducts(threshold, limit);
  }

  @Get('analytics/recent-signups')
  @ApiOperation({ summary: 'Get recent user signups' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  getRecentSignups(
    @Query('limit', new DefaultValuePipe(5), ParseIntPipe) limit: number = 5,
  ) {
    return this.adminService.getRecentSignups(limit);
  }

  // ==========================================
  // PRODUCTS - ✅ PAGINATED
  // ==========================================
  @Get('products/all')
  @ApiOperation({ summary: 'Get all products for admin (paginated)' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'categoryId', required: false })
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
  @ApiOperation({ summary: 'Get product details for admin' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  getProductById(@Param('productId', ParseUUIDPipe) productId: string) {
    return this.adminService.getProductById(productId);
  }
  // In admin.controller.ts
  @Post('products')
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

    console.log(
      '📦 Create Product Data:',
      JSON.stringify(createProductDto).substring(0, 200),
    );
    console.log('🖼️ Files received:', files?.length || 0);

    // Create product with variants
    const product = await this.adminService.createProduct(createProductDto);

    // Upload images if any
    if (files && files.length > 0) {
      await this.adminService.uploadProductImages(product.id, files);
    }

    // Return the complete product with images
    return this.adminService.getProductById(product.id);
  }

  // Fix the updateProduct method in admin.controller.ts

  // In admin.controller.ts - updateProduct method
  @Put('products/:productId')
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

    console.log('📦 Update Data keys:', Object.keys(updateData));
    console.log('🖼️ Files received:', files?.length || 0);

    // ✅ Pass files directly to service - don't call uploadProductImages separately
    return this.adminService.updateProduct(productId, updateData, files || []);
  }
  @Delete('products/:productId')
  @ApiOperation({ summary: 'Delete product' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  deleteProduct(@Param('productId', ParseUUIDPipe) productId: string) {
    return this.adminService.deleteProduct(productId);
  }

  @Post('products/:productId/images')
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
  // CATEGORIES
  // ==========================================
  @Get('categories/tree')
  @ApiOperation({
    summary: 'Get categories as tree structure (including inactive)',
  })
  getCategoriesTree() {
    return this.adminService.getCategoriesTree();
  }

  @Post('categories')
  @ApiOperation({ summary: 'Create a new category' })
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
  @ApiOperation({ summary: 'Update category' })
  updateCategory(
    @Param('categoryId', ParseUUIDPipe) categoryId: string,
    @Body() data: { name?: string; slug?: string; description?: string },
  ) {
    return this.adminService.updateCategory(categoryId, data);
  }
  @Delete('categories/:categoryId')
  @ApiOperation({ summary: 'Delete category with optional product transfer' })
  @ApiQuery({ name: 'transferToId', required: false })
  deleteCategory(
    @Param('categoryId', ParseUUIDPipe) categoryId: string,
    @Query('transferToId') transferToId?: string, // ✅ Read query param
  ) {
    return this.adminService.deleteCategory(categoryId, transferToId);
  }
}
