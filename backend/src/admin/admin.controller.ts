import {
  Controller,
  Get,
  Put,
  UseGuards,
  Query,
  Param,
  Body,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiParam,
  ApiBody,
} from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { AdminGuard, JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
@ApiBearerAuth('JWT-auth')
export class AdminController {
  constructor(private adminService: AdminService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Get admin dashboard statistics' })
  getStats() {
    return this.adminService.getStats();
  }

  @Get('orders')
  @ApiOperation({ summary: 'Get all orders with optional search' })
  @ApiQuery({
    name: 'search',
    required: false,
    description: 'Search by order number or customer name',
  })
  getAllOrders(@Query('search') search?: string) {
    return this.adminService.getAllOrders(search);
  }

  // ✅ NEW: Admin-specific status update endpoint
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
          example: 'SHIPPED',
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

  @Get('products')
  @ApiOperation({ summary: 'Get all products' })
  getAllProducts() {
    return this.adminService.getAllProducts();
  }

  @Get('users')
  @ApiOperation({ summary: 'Get all users' })
  getAllUsers() {
    return this.adminService.getAllUsers();
  }
}
