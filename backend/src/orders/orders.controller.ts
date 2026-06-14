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
import { ProcessPaymentDto } from './dto/process-payment.dto';
import { AddToCartDto } from './dto/add-to-cart.dto'; // Ensure this DTO exists!

@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  // ==========================================
  // 1. ADDRESS ENDPOINTS (Static)
  // ==========================================
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

  // ==========================================
  // 2. CART ENDPOINTS (Static - MOVED UP!)
  // ==========================================
  @Get('cart')
  async getCart(@Request() req) {
    return this.ordersService.getCart(req.user.userId);
  }

  @Post('cart')
  async addToCart(@Request() req, @Body() addToCartDto: AddToCartDto) {
    return this.ordersService.addToCart(
      req.user.userId,
      addToCartDto.productVariantId,
      addToCartDto.quantity,
    );
  }

  @Put('cart/:itemId')
  async updateCartItem(
    @Request() req,
    @Param('itemId') itemId: string,
    @Body('quantity') quantity: number,
  ) {
    return this.ordersService.updateCartItem(req.user.userId, itemId, quantity);
  }

  @Delete('cart/:itemId')
  async removeCartItem(@Request() req, @Param('itemId') itemId: string) {
    return this.ordersService.removeCartItem(req.user.userId, itemId);
  }

  @Delete('cart')
  async clearCart(@Request() req) {
    return this.ordersService.clearCart(req.user.userId);
  }

  // ==========================================
  // 3. NOTIFICATION ENDPOINTS (Static)
  // ==========================================
  @Get('notifications')
  async getNotifications(@Request() req) {
    return this.ordersService.getUserNotifications(req.user.userId);
  }

  @Get('notifications/unread/count')
  async getUnreadCount(@Request() req) {
    return this.ordersService.getUnreadCount(req.user.userId);
  }

  @Put('notifications/read-all')
  async markAllAsRead(@Request() req) {
    return this.ordersService.markAllNotificationsAsRead(req.user.userId);
  }

  @Put('notifications/:id/read')
  async markNotificationAsRead(@Request() req, @Param('id') id: string) {
    return this.ordersService.markNotificationAsRead(id, req.user.userId);
  }

  @Delete('notifications/:id')
  async deleteNotification(@Request() req, @Param('id') id: string) {
    return this.ordersService.deleteNotification(id, req.user.userId);
  }

  // ==========================================
  // 4. ORDER ENDPOINTS
  // ==========================================
  @Post()
  async createOrder(@Request() req, @Body() createOrderDto: CreateOrderDto) {
    return this.ordersService.createOrder(req.user.userId, createOrderDto);
  }

  @Get()
  async getOrders(@Request() req, @Query('status') status?: string) {
    return this.ordersService.getOrders(req.user.userId, status);
  }

  @Post(':id/payment')
  async processPayment(
    @Request() req,
    @Param('id') id: string,
    @Body() paymentData: ProcessPaymentDto,
  ) {
    return this.ordersService.processPayment(id, req.user.userId, paymentData);
  }

  // ==========================================
  // 5. DYNAMIC ORDER ROUTES (MUST BE LAST!)
  // ==========================================
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
}
