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
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { SuperAdminGuard } from '../auth/guards/super-admin.guard';
import { PermissionGuard, Permissions } from '../auth/guards/permission.guard';
import { Permission } from './enums/permissions.enum';

@ApiTags('admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard, PermissionGuard)
@ApiBearerAuth('JWT-auth')
export class AdminController {
  constructor(private adminService: AdminService) {}

  // ==========================================
  // ✅ MY PERMISSIONS
  // Any admin can get their own permissions
  // Must be near the top
  // ==========================================
  @Get('me/permissions')
  @Permissions()
  @ApiOperation({ summary: 'Get my own permissions (any admin)' })
  @ApiResponse({
    status: 200,
    description: 'Permissions retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Admin access required',
  })
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
  @ApiResponse({
    status: 200,
    description: 'Statistics retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getStats() {
    return this.adminService.getStats();
  }

  // ==========================================
  // ROLE MANAGEMENT
  // ==========================================

  @Get('roles')
  @Permissions(Permission.ADMIN_VIEW)
  @ApiOperation({ summary: 'Get all roles' })
  @ApiResponse({ status: 200, description: 'Roles retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  async getAllRoles() {
    return this.adminService.getAllRoles();
  }

  @Post('roles')
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
  @ApiResponse({ status: 201, description: 'Role created successfully' })
  @ApiResponse({ status: 400, description: 'Invalid role data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  async createRole(
    @Body() data: { name: string; description?: string; permissions: string[] },
  ) {
    return this.adminService.createRole(data);
  }

  @Put('roles/:roleId')
  @Permissions(Permission.ADMIN_UPDATE)
  @ApiOperation({ summary: 'Update a role' })
  @ApiParam({ name: 'roleId', description: 'Role UUID' })
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
  @ApiResponse({ status: 200, description: 'Role updated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid role data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Role not found' })
  async updateRole(
    @Param('roleId', ParseUUIDPipe) roleId: string,
    @Body()
    data: { name?: string; description?: string; permissions?: string[] },
  ) {
    return this.adminService.updateRole(roleId, data);
  }

  @Delete('roles/:roleId')
  @Permissions(Permission.ADMIN_DELETE)
  @ApiOperation({ summary: 'Delete a role' })
  @ApiParam({ name: 'roleId', description: 'Role UUID' })
  @ApiResponse({ status: 200, description: 'Role deleted successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Role not found' })
  async deleteRole(@Param('roleId', ParseUUIDPipe) roleId: string) {
    return this.adminService.deleteRole(roleId);
  }

  // ==========================================
  // USER ROLE ASSIGNMENT
  // ==========================================

  @Post('users/:userId/roles')
  @Permissions(Permission.ADMIN_UPDATE)
  @ApiOperation({ summary: 'Assign a role to a user' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        roleId: { type: 'string' },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'Role assigned successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'User or role not found' })
  async assignRoleToUser(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body('roleId') roleId: string,
  ) {
    return this.adminService.assignRoleToUser(userId, roleId);
  }

  @Delete('users/:userId/roles/:roleId')
  @Permissions(Permission.ADMIN_UPDATE)
  @ApiOperation({ summary: 'Remove a role from a user' })
  @ApiParam({ name: 'userId', description: 'User UUID' })
  @ApiParam({ name: 'roleId', description: 'Role UUID' })
  @ApiResponse({ status: 200, description: 'Role removed successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'User or role not found' })
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
  @ApiResponse({
    status: 200,
    description: 'User roles retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'User not found' })
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
  @ApiResponse({
    status: 200,
    description: 'User permissions retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'User not found' })
  async getUserPermissions(@Param('userId', ParseUUIDPipe) userId: string) {
    const permissions = await this.adminService.getUserPermissions(userId);
    return { permissions };
  }

  // ==========================================
  // DASHBOARD
  // ==========================================
  @Get('dashboard/all')
  @ApiOperation({
    summary: 'Get all dashboard data in one request (Optimized)',
  })
  async getAllDashboardData(
    @Request() req,
    @Query('period') period: string = 'week',
  ) {
    return this.adminService.getAllDashboardData(req.user.userId, period);
  }

  @Get('dashboard/stats')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get dashboard statistics with period' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  @ApiResponse({
    status: 200,
    description: 'Dashboard statistics retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getDashboardStats(@Query('period') period: string = 'week') {
    return this.adminService.getDashboardStats(period);
  }

  @Get('dashboard/users-chart')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get users registration chart data' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  @ApiResponse({
    status: 200,
    description: 'Users chart data retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getUsersChartData(@Query('period') period: string = 'week') {
    return this.adminService.getUsersChartData(period);
  }

  @Get('dashboard/revenue-chart')
  @Permissions(Permission.REVENUE_VIEW)
  @ApiOperation({ summary: 'Get revenue chart data' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  @ApiResponse({
    status: 200,
    description: 'Revenue chart data retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getRevenueChart(@Query('period') period: string = 'week') {
    return this.adminService.getRevenueChart(period);
  }

  @Get('dashboard/device-traffic')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get device traffic distribution' })
  @ApiResponse({
    status: 200,
    description: 'Device traffic data retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getDeviceTraffic() {
    return this.adminService.getDeviceTraffic();
  }

  @Get('dashboard/location-traffic')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get location traffic distribution' })
  @ApiResponse({
    status: 200,
    description: 'Location traffic data retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getLocationTraffic() {
    return this.adminService.getLocationTraffic();
  }

  @Get('dashboard/product-traffic')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get product traffic' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  @ApiResponse({
    status: 200,
    description: 'Product traffic data retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getProductTraffic(@Query('period') period: string = 'week') {
    return this.adminService.getProductTraffic(period);
  }

  @Get('dashboard/recent-orders')
  @Permissions(Permission.ORDER_VIEW)
  @ApiOperation({ summary: 'Get recent orders' })
  @ApiQuery({ name: 'limit', required: false })
  @ApiResponse({
    status: 200,
    description: 'Recent orders retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
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
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  @ApiResponse({
    status: 200,
    description: 'Revenue summary retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getRevenueSummary(@Query('period') period: string = 'week') {
    return this.adminService.getRevenueSummary(period);
  }

  @Get('revenue')
  @Permissions(Permission.REVENUE_VIEW)
  @ApiOperation({ summary: 'Get all revenue records with filters' })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'paymentMethod', required: false })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({
    status: 200,
    description: 'Revenue records retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
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
  @ApiResponse({
    status: 200,
    description: 'Revenue details retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Order not found' })
  getRevenueById(@Param('orderId', ParseUUIDPipe) orderId: string) {
    return this.adminService.getRevenueById(orderId);
  }

  // ==========================================
  // ORDERS
  // ==========================================
  @Get('orders')
  @Permissions(Permission.ORDER_VIEW)
  @ApiOperation({ summary: 'Get all orders with pagination' })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false })
  @ApiResponse({ status: 200, description: 'Orders retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getAllOrders(
    @Query('search') search?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('status') status?: string,
  ) {
    return this.adminService.getAllOrders(search, page, limit, status);
  }

  @Put('orders/:orderId/status')
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
  @ApiResponse({
    status: 200,
    description: 'Order status updated successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid status' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Order not found' })
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
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Users retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
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
  @ApiResponse({ status: 200, description: 'User retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'User not found' })
  getUserById(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.adminService.getUserById(userId);
  }

  @Post('users')
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
  @ApiResponse({ status: 201, description: 'User created successfully' })
  @ApiResponse({ status: 400, description: 'Invalid user data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
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
  @Permissions(Permission.USER_UPDATE)
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
  @ApiResponse({ status: 200, description: 'User updated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid update data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'User not found' })
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
  @ApiResponse({
    status: 200,
    description: 'Admin status updated successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Super admin access required',
  })
  @ApiResponse({ status: 404, description: 'User not found' })
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
  @ApiResponse({ status: 200, description: 'User deleted successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Super admin access required',
  })
  @ApiResponse({ status: 404, description: 'User not found' })
  deleteUser(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.adminService.deleteUser(userId);
  }

  // ==========================================
  // COLORS
  // ==========================================
  @Get('colors/all')
  @Permissions(Permission.COLOR_VIEW)
  @ApiOperation({ summary: 'Get all colors' })
  @ApiResponse({ status: 200, description: 'Colors retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getAllColors() {
    return this.adminService.getAllColors();
  }

  @Post('colors')
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
  @ApiResponse({ status: 201, description: 'Color created successfully' })
  @ApiResponse({ status: 400, description: 'Invalid color data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  createColor(@Body() data: { name: string; code: string }) {
    return this.adminService.createColor(data);
  }

  @Put('colors/:colorId')
  @Permissions(Permission.COLOR_UPDATE)
  @ApiOperation({ summary: 'Update color' })
  @ApiParam({ name: 'colorId', description: 'Color UUID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        code: { type: 'string' },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'Color updated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid color data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Color not found' })
  updateColor(
    @Param('colorId', ParseUUIDPipe) colorId: string,
    @Body() data: { name?: string; code?: string },
  ) {
    return this.adminService.updateColor(colorId, data);
  }

  @Delete('colors/:colorId')
  @Permissions(Permission.COLOR_DELETE)
  @ApiOperation({ summary: 'Delete color' })
  @ApiParam({ name: 'colorId', description: 'Color UUID' })
  @ApiResponse({ status: 200, description: 'Color deleted successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Color not found' })
  deleteColor(@Param('colorId', ParseUUIDPipe) colorId: string) {
    return this.adminService.deleteColor(colorId);
  }

  // ==========================================
  // SIZES
  // ==========================================
  @Get('sizes/all')
  @Permissions(Permission.SIZE_VIEW)
  @ApiOperation({ summary: 'Get all sizes' })
  @ApiResponse({ status: 200, description: 'Sizes retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getAllSizes() {
    return this.adminService.getAllSizes();
  }

  @Post('sizes')
  @Permissions(Permission.SIZE_CREATE)
  @ApiOperation({ summary: 'Create a new size' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'Large' },
        value: { type: 'string', example: 'L' },
      },
      required: ['name', 'value'],
    },
  })
  @ApiResponse({ status: 201, description: 'Size created successfully' })
  @ApiResponse({ status: 400, description: 'Invalid size data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  createSize(@Body() data: { name: string; value: string }) {
    return this.adminService.createSize(data);
  }

  @Put('sizes/:sizeId')
  @Permissions(Permission.SIZE_UPDATE)
  @ApiOperation({ summary: 'Update size' })
  @ApiParam({ name: 'sizeId', description: 'Size UUID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        value: { type: 'string' },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'Size updated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid size data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Size not found' })
  updateSize(
    @Param('sizeId', ParseUUIDPipe) sizeId: string,
    @Body() data: { name?: string; value?: string },
  ) {
    return this.adminService.updateSize(sizeId, data);
  }

  @Delete('sizes/:sizeId')
  @Permissions(Permission.SIZE_DELETE)
  @ApiOperation({ summary: 'Delete size' })
  @ApiParam({ name: 'sizeId', description: 'Size UUID' })
  @ApiResponse({ status: 200, description: 'Size deleted successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Size not found' })
  deleteSize(@Param('sizeId', ParseUUIDPipe) sizeId: string) {
    return this.adminService.deleteSize(sizeId);
  }

  // ==========================================
  // MARKETS
  // ==========================================
  @Get('markets/all')
  @Permissions(Permission.MARKET_VIEW)
  @ApiOperation({ summary: 'Get all markets with user count' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Markets retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getAllMarkets(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
  ) {
    return this.adminService.getAllMarkets(page, limit);
  }

  @Post('markets')
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
  @ApiResponse({ status: 201, description: 'Market created successfully' })
  @ApiResponse({ status: 400, description: 'Invalid market data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
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
  @ApiResponse({ status: 200, description: 'Market updated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid update data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Market not found' })
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
  @ApiResponse({ status: 200, description: 'Market deactivated successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Market not found' })
  deactivateMarket(@Param('marketId', ParseUUIDPipe) marketId: string) {
    return this.adminService.deactivateMarket(marketId);
  }

  @Delete('markets/:marketId')
  @Permissions(Permission.MARKET_DELETE)
  @ApiOperation({ summary: 'Delete market (only if no users)' })
  @ApiParam({ name: 'marketId', description: 'Market UUID' })
  @ApiResponse({ status: 200, description: 'Market deleted successfully' })
  @ApiResponse({ status: 400, description: 'Cannot delete market with users' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Market not found' })
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
  @ApiResponse({
    status: 200,
    description: 'Enhanced analytics retrieved successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid date range' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
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
  @ApiResponse({
    status: 200,
    description: 'Revenue data retrieved successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid date range' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
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
  @ApiResponse({
    status: 200,
    description: 'Analytics data retrieved successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid date format' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
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
  @ApiResponse({
    status: 200,
    description: 'Revenue data retrieved successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid date format' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
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
  // PRODUCTS
  // ==========================================
  @Get('products/list')
  @Permissions(Permission.PRODUCT_VIEW)
  @ApiOperation({
    summary: 'Get ALL products without pagination',
    description: 'Returns all products for admin management',
  })
  @ApiResponse({ status: 200, description: 'Products retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getAllProductsList() {
    return this.adminService.getAllProducts();
  }

  @Get('products/all')
  @Permissions(Permission.PRODUCT_VIEW)
  @ApiOperation({ summary: 'Get all products for admin (paginated)' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'categoryId', required: false })
  @ApiResponse({ status: 200, description: 'Products retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
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
  @ApiResponse({ status: 200, description: 'Product retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Product not found' })
  getProductById(@Param('productId', ParseUUIDPipe) productId: string) {
    return this.adminService.getProductById(productId);
  }

  @Post('products')
  @Permissions(Permission.PRODUCT_CREATE)
  @ApiOperation({ summary: 'Create a new product with images and variants' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(AnyFilesInterceptor())
  @ApiResponse({ status: 201, description: 'Product created successfully' })
  @ApiResponse({ status: 400, description: 'Invalid product data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
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

    const product = await this.adminService.createProduct(createProductDto);

    if (files && files.length > 0) {
      await this.adminService.uploadProductImages(product.id, files);
    }

    return this.adminService.getProductById(product.id);
  }

  @Put('products/:productId')
  @Permissions(Permission.PRODUCT_UPDATE)
  @ApiOperation({ summary: 'Update product with variants and images' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(AnyFilesInterceptor())
  @ApiResponse({ status: 200, description: 'Product updated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid update data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Product not found' })
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

    return this.adminService.updateProduct(productId, updateData, files || []);
  }

  @Delete('products/:productId')
  @Permissions(Permission.PRODUCT_DELETE)
  @ApiOperation({ summary: 'Delete product' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  @ApiResponse({ status: 200, description: 'Product deleted successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Product not found' })
  deleteProduct(@Param('productId', ParseUUIDPipe) productId: string) {
    return this.adminService.deleteProduct(productId);
  }

  @Post('products/:productId/images')
  @Permissions(Permission.PRODUCT_UPDATE)
  @ApiOperation({ summary: 'Upload product images' })
  @ApiParam({ name: 'productId', description: 'Product UUID' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('images', { limits: { fileSize: 5 * 1024 * 1024 } }),
  )
  @ApiResponse({ status: 200, description: 'Images uploaded successfully' })
  @ApiResponse({ status: 400, description: 'Invalid images' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Product not found' })
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
  @ApiResponse({
    status: 200,
    description: 'Analytics data retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getAllAnalytics(@Query('period') period: string = 'week') {
    return this.adminService.getAllAnalytics(period);
  }

  @Get('analytics/top-products')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get top selling products' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  @ApiResponse({
    status: 200,
    description: 'Top products retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getTopSellingProducts(
    @Query('limit', new DefaultValuePipe(5), ParseIntPipe) limit: number = 5,
    @Query('period') period: string = 'week',
  ) {
    return this.adminService.getTopSellingProducts(limit, period);
  }

  @Get('analytics/revenue-by-category')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get revenue breakdown by category' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  @ApiResponse({
    status: 200,
    description: 'Revenue by category retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getRevenueByCategory(@Query('period') period: string = 'week') {
    return this.adminService.getRevenueByCategory(period);
  }

  @Get('analytics/order-status')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get order status distribution' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  @ApiResponse({
    status: 200,
    description: 'Order status distribution retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getOrderStatusDistribution(@Query('period') period: string = 'week') {
    return this.adminService.getOrderStatusDistribution(period);
  }

  @Get('analytics/low-stock')
  @Permissions(Permission.ANALYTICS_VIEW)
  @ApiOperation({ summary: 'Get low stock products' })
  @ApiQuery({ name: 'threshold', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({
    status: 200,
    description: 'Low stock products retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
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
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({
    status: 200,
    description: 'Recent signups retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
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
  @ApiOperation({
    summary: 'Get categories as tree structure (including inactive)',
  })
  @ApiResponse({
    status: 200,
    description: 'Categories tree retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  getCategoriesTree() {
    return this.adminService.getCategoriesTree();
  }

  @Post('categories')
  @Permissions(Permission.CATEGORY_CREATE)
  @ApiOperation({ summary: 'Create a new category' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'Electronics' },
        slug: { type: 'string', example: 'electronics' },
        description: {
          type: 'string',
          example: 'Electronic devices and accessories',
        },
        parentId: {
          type: 'string',
          example: '550e8400-e29b-41d4-a716-446655440000',
        },
      },
      required: ['name'],
    },
  })
  @ApiResponse({ status: 201, description: 'Category created successfully' })
  @ApiResponse({ status: 400, description: 'Invalid category data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
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
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        slug: { type: 'string' },
        description: { type: 'string' },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'Category updated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid update data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Category not found' })
  updateCategory(
    @Param('categoryId', ParseUUIDPipe) categoryId: string,
    @Body() data: { name?: string; slug?: string; description?: string },
  ) {
    return this.adminService.updateCategory(categoryId, data);
  }

  @Delete('categories/:categoryId')
  @Permissions(Permission.CATEGORY_DELETE)
  @ApiOperation({ summary: 'Delete category with optional product transfer' })
  @ApiParam({ name: 'categoryId', description: 'Category UUID' })
  @ApiQuery({ name: 'transferToId', required: false })
  @ApiResponse({ status: 200, description: 'Category deleted successfully' })
  @ApiResponse({ status: 400, description: 'Cannot delete category' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Insufficient permissions',
  })
  @ApiResponse({ status: 404, description: 'Category not found' })
  deleteCategory(
    @Param('categoryId', ParseUUIDPipe) categoryId: string,
    @Query('transferToId') transferToId?: string,
  ) {
    return this.adminService.deleteCategory(categoryId, transferToId);
  }
}
