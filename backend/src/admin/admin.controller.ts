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
import { CreateProductAdminDto } from './dto/create-proudct-admin-dto';
import { AdminGuard } from 'src/auth/guards/admin.guard';

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
  // 🚀 OPTIMIZED: ALL DASHBOARD DATA IN ONE REQUEST
  // ==========================================
  @Get('dashboard/all')
  @ApiOperation({
    summary: 'Get all dashboard data in one request (Optimized)',
  })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
    description: 'Time period for dashboard data',
  })
  async getAllDashboardData(@Query('period') period: string = 'week') {
    return this.adminService.getAllDashboardData(period);
  }
  // Add these endpoints to AdminController

  @Get('colors')
  @ApiOperation({ summary: 'Get all colors' })
  getColors() {
    return this.adminService.getColors();
  }

  @Get('sizes')
  @ApiOperation({ summary: 'Get all sizes' })
  getSizes() {
    return this.adminService.getSizes();
  }
  // ==========================================
  // DASHBOARD STATS
  // ==========================================
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

  // ==========================================
  // USERS CHART
  // ==========================================
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

  // ==========================================
  // REVENUE CHART
  // ==========================================
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

  // ==========================================
  // DEVICE TRAFFIC
  // ==========================================
  @Get('dashboard/device-traffic')
  @ApiOperation({ summary: 'Get device traffic distribution' })
  getDeviceTraffic() {
    return this.adminService.getDeviceTraffic();
  }

  // ==========================================
  // LOCATION TRAFFIC
  // ==========================================
  @Get('dashboard/location-traffic')
  @ApiOperation({ summary: 'Get location traffic distribution' })
  getLocationTraffic() {
    return this.adminService.getLocationTraffic();
  }

  // ==========================================
  // PRODUCT TRAFFIC
  // ==========================================
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

  // ==========================================
  // RECENT ORDERS
  // ==========================================
  @Get('dashboard/recent-orders')
  @ApiOperation({ summary: 'Get recent orders' })
  @ApiQuery({ name: 'limit', required: false })
  getRecentOrders(@Query('limit') limit: number = 5) {
    return this.adminService.getRecentOrders(limit);
  }

  // ==========================================
  // 🆕 REVENUE ENDPOINTS (MUST BE BEFORE :orderId)
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
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'offset', required: false, type: Number })
  getAllRevenue(
    @Query('search') search?: string,
    @Query('paymentMethod') paymentMethod?: string,
    @Query('status') status?: string,
    @Query('limit') limit: number = 50,
    @Query('offset') offset: number = 0,
  ) {
    return this.adminService.getAllRevenue(
      search,
      paymentMethod,
      status,
      limit,
      offset,
    );
  }

  @Get('revenue/:orderId')
  @ApiOperation({ summary: 'Get revenue details by order ID' })
  @ApiParam({ name: 'orderId', description: 'Order UUID' })
  getRevenueById(@Param('orderId') orderId: string) {
    return this.adminService.getRevenueById(orderId);
  }

  // ==========================================
  // ORDERS
  // ==========================================
  @Get('orders')
  @ApiOperation({ summary: 'Get all orders with optional search' })
  @ApiQuery({ name: 'search', required: false })
  getAllOrders(@Query('search') search?: string) {
    return this.adminService.getAllOrders(search);
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
    @Param('orderId') orderId: string,
    @Body('status') status: string,
  ) {
    return this.adminService.updateOrderStatus(orderId, status);
  }

  // ==========================================
  // USERS
  // ==========================================
  @Get('users')
  @ApiOperation({ summary: 'Get all users' })
  @ApiQuery({ name: 'search', required: false })
  getAllUsers(@Query('search') search?: string) {
    return this.adminService.getAllUsers(search);
  }
  @Get('users/:userId')
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  getUserById(@Param('userId') userId: string) {
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
        isAdmin: { type: 'boolean' },
      },
    },
  })
  updateUser(
    @Param('userId') userId: string,
    @Body()
    updateData: {
      name?: string;
      email?: string;
      marketId?: string;
      isAdmin?: boolean;
    },
  ) {
    return this.adminService.updateUser(userId, updateData);
  }

  @Delete('users/:userId')
  @ApiOperation({ summary: 'Delete user' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  deleteUser(@Param('userId') userId: string) {
    return this.adminService.deleteUser(userId);
  }

  // ==========================================
  // ADMIN PRODUCTS MANAGEMENT
  // ==========================================
  @Get('products/all')
  @ApiOperation({ summary: 'Get all products for admin (including inactive)' })
  getAllProductsAdmin() {
    return this.adminService.getAllProductsAdmin();
  }

  @Get('products/:productId')
  @ApiOperation({ summary: 'Get product details for admin' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  getProductById(@Param('productId') productId: string) {
    return this.adminService.getProductById(productId);
  }

  @Post('products')
  @ApiOperation({ summary: 'Create a new product' })
  @ApiBody({ type: CreateProductAdminDto })
  createProduct(@Body() createProductDto: CreateProductAdminDto) {
    return this.adminService.createProduct(createProductDto);
  }
  @Put('products/:productId')
  @ApiOperation({ summary: 'Update product' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  updateProduct(
    @Param('productId') productId: string,
    @Body() updateData: any,
  ) {
    return this.adminService.updateProduct(productId, updateData);
  }

  @Delete('products/:productId')
  @ApiOperation({ summary: 'Delete product' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  deleteProduct(@Param('productId') productId: string) {
    return this.adminService.deleteProduct(productId);
  }

  @Get('categories/tree')
  @ApiOperation({ summary: 'Get categories as tree structure' })
  getCategoriesTree() {
    return this.adminService.getCategoriesTree();
  }

  @Post('products/:productId/images')
  @ApiOperation({ summary: 'Upload product images' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('images', {
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  uploadProductImages(
    @Param('productId') productId: string,
    @UploadedFiles() images: Express.Multer.File[],
  ) {
    return this.adminService.uploadProductImages(productId, images);
  }
}
