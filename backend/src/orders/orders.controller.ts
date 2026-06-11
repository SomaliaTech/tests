import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Put,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AddressDto } from './dto/address.dto';

@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  // Address endpoints
  @Post('addresses')
  async addAddress(@Request() req, @Body() addressData: AddressDto) {
    return this.ordersService.addAddress(req.user.userId, addressData);
  }

  @Get('addresses')
  async getAddresses(@Request() req) {
    return this.ordersService.getAddresses(req.user.userId);
  }

  @Get('addresses/default')
  async getDefaultAddress(@Request() req) {
    return this.ordersService.getDefaultAddress(req.user.userId);
  }

  @Put('addresses/:addressId/default')
  async setDefaultAddress(
    @Request() req,
    @Param('addressId') addressId: string,
  ) {
    return this.ordersService.setDefaultAddress(req.user.userId, addressId);
  }

  @Delete('addresses/:addressId')
  async deleteAddress(@Request() req, @Param('addressId') addressId: string) {
    return this.ordersService.deleteAddress(req.user.userId, addressId);
  }

  // Order endpoints
  @Post()
  async createOrder(
    @Request() req,
    @Body() createOrderDto: CreateOrderDto,
  ): Promise<any> {
    return this.ordersService.createOrder(req.user.userId, createOrderDto);
  }

  @Get()
  async getOrders(@Request() req, @Query('status') status?: string) {
    return this.ordersService.getOrders(req.user.userId, status);
  }

  @Get(':id')
  async getOrderById(@Request() req, @Param('id') id: string) {
    return this.ordersService.getOrderById(id, req.user.userId);
  }

  @Put(':id/status')
  async updateOrderStatus(
    @Param('id') id: string,
    @Body('status') status: string,
  ) {
    return this.ordersService.updateOrderStatus(id, status);
  }

  // Notification endpoints
  @Get('notifications')
  async getNotifications(@Request() req) {
    return this.ordersService.getUserNotifications(req.user.userId);
  }

  @Get('notifications/unread/count')
  async getUnreadCount(@Request() req) {
    return this.ordersService.getUnreadCount(req.user.userId);
  }

  @Put('notifications/:id/read')
  async markNotificationAsRead(@Request() req, @Param('id') id: string) {
    return this.ordersService.markNotificationAsRead(id, req.user.userId);
  }

  @Put('notifications/read-all')
  async markAllAsRead(@Request() req) {
    return this.ordersService.markAllNotificationsAsRead(req.user.userId);
  }

  @Delete('notifications/:id')
  async deleteNotification(@Request() req, @Param('id') id: string) {
    return this.ordersService.deleteNotification(id, req.user.userId);
  }
}
