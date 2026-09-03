// src/orders/orders.controller.ts

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
  ParseUUIDPipe,
  DefaultValuePipe,
  ParseIntPipe,
  BadRequestException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiBody,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard, Permissions } from '../auth/guards/permission.guard';
import { OwnershipGuard } from './guards/ownership.guard';
import { AddressDto } from './dto/address.dto';
import { AddToCartDto } from '../products/dto/cart.dto';
import { Permission } from '../admin/enums/permissions.enum';
import { OrderStatus } from './enums/order-status.enum';

@ApiTags('orders')
@Controller('orders')
@UseGuards(JwtAuthGuard, ThrottlerGuard)
@ApiBearerAuth('JWT-auth')
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  // ==========================================
  // 1. ADDRESS ENDPOINTS
  // ==========================================

  @Post('addresses')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Add a new address' })
  @ApiBody({ type: AddressDto })
  async addAddress(@Request() req, @Body() addressData: AddressDto) {
    return this.ordersService.addAddress(req.user.userId, addressData);
  }

  @Get('addresses')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Get all addresses' })
  async getAddresses(@Request() req) {
    return this.ordersService.getAddresses(req.user.userId);
  }

  @Get('addresses/default')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Get default address' })
  async getDefaultAddress(@Request() req) {
    return this.ordersService.getDefaultAddress(req.user.userId);
  }

  @Put('addresses/:addressId/default')
  @UseGuards(OwnershipGuard)
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({ summary: 'Set default address' })
  @ApiParam({ name: 'addressId', description: 'Address UUID' })
  async setDefaultAddress(
    @Request() req,
    @Param('addressId', ParseUUIDPipe) addressId: string,
  ) {
    return this.ordersService.setDefaultAddress(req.user.userId, addressId);
  }

  @Delete('addresses/:addressId')
  @UseGuards(OwnershipGuard)
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({ summary: 'Delete address' })
  @ApiParam({ name: 'addressId', description: 'Address UUID' })
  async deleteAddress(
    @Request() req,
    @Param('addressId', ParseUUIDPipe) addressId: string,
  ) {
    return this.ordersService.deleteAddress(req.user.userId, addressId);
  }

  // ==========================================
  // 2. CART ENDPOINTS
  // ==========================================

  @Get('cart')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Get shopping cart' })
  async getCart(@Request() req) {
    return this.ordersService.getCart(req.user.userId);
  }

  @Post('cart')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Add to cart' })
  @ApiBody({ type: AddToCartDto })
  async addToCart(@Request() req, @Body() addToCartDto: AddToCartDto) {
    return this.ordersService.addToCart(req.user.userId, addToCartDto);
  }

  @Put('cart/:itemId')
  @UseGuards(OwnershipGuard)
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Update cart item quantity' })
  @ApiParam({ name: 'itemId', description: 'Cart item UUID' })
  async updateCartItem(
    @Request() req,
    @Param('itemId', ParseUUIDPipe) itemId: string,
    @Body('quantity') quantity: number,
  ) {
    return this.ordersService.updateCartItem(req.user.userId, itemId, quantity);
  }

  @Delete('cart/:itemId')
  @UseGuards(OwnershipGuard)
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Remove item from cart' })
  @ApiParam({ name: 'itemId', description: 'Cart item UUID' })
  async removeCartItem(
    @Request() req,
    @Param('itemId', ParseUUIDPipe) itemId: string,
  ) {
    return this.ordersService.removeCartItem(req.user.userId, itemId);
  }

  @Delete('cart')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Clear cart' })
  async clearCart(@Request() req) {
    return this.ordersService.clearCart(req.user.userId);
  }

  // ==========================================
  // 3. ORDER ENDPOINTS
  // ==========================================

  @Post()
  @Throttle({ payment: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Create a new order with payment' })
  @ApiBody({ type: CreateOrderDto })
  async createOrder(@Request() req, @Body() createOrderDto: CreateOrderDto) {
    return this.ordersService.createOrder(req.user.userId, createOrderDto);
  }

  @Get()
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Get user orders' })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getOrders(
    @Request() req,
    @Query('status') status?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number = 10,
  ) {
    return this.ordersService.getOrders(req.user.userId, status, page, limit);
  }

  @Get(':id')
  @UseGuards(OwnershipGuard)
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Get order by ID' })
  @ApiParam({ name: 'id', description: 'Order UUID' })
  async getOrderById(@Request() req, @Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.getOrderById(id, req.user.userId);
  }

  @Put(':id/status')
  @UseGuards(PermissionGuard)
  @Permissions(Permission.ORDER_UPDATE)
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({ summary: 'Update order status (Admin)' })
  @ApiParam({ name: 'id', description: 'Order UUID' })
  @ApiBody({ schema: { properties: { status: { type: 'string' } } } })
  async updateOrderStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('status') status: OrderStatus,
  ) {
    return this.ordersService.updateOrderStatus(id, status);
  }

  @Post(':id/cancel')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Cancel order' })
  @ApiParam({ name: 'id', description: 'Order UUID' })
  @ApiBody({ schema: { properties: { reason: { type: 'string' } } } })
  async cancelOrder(
    @Request() req,
    @Param('id', ParseUUIDPipe) id: string,
    @Body('reason') reason?: string,
  ) {
    return this.ordersService.cancelOrder(id, req.user.userId, reason);
  }
}
