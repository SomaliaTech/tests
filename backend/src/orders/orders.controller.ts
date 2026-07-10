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
  ApiResponse,
  ApiBody,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AddressDto } from './dto/address.dto';
import { ProcessPaymentDto } from './dto/process-payment.dto';
import { AddToCartDto } from '../products/dto/cart.dto';

@ApiTags('orders')
@Controller('orders')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  // ==========================================
  // 1. ADDRESS ENDPOINTS
  // ==========================================

  @Post('addresses')
  @ApiOperation({
    summary: 'Add a new address',
    description: 'Adds a new shipping address for the authenticated user.',
  })
  @ApiBody({ type: AddressDto })
  @ApiResponse({
    status: 201,
    description: 'Address added successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid address data',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async addAddress(@Request() req, @Body() addressData: AddressDto) {
    return this.ordersService.addAddress(req.user.userId, addressData);
  }

  @Get('addresses')
  @ApiOperation({
    summary: 'Get all addresses',
    description: 'Returns all shipping addresses for the authenticated user.',
  })
  @ApiResponse({
    status: 200,
    description: 'Addresses retrieved successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async getAddresses(@Request() req) {
    return this.ordersService.getAddresses(req.user.userId);
  }

  @Get('addresses/default')
  @ApiOperation({
    summary: 'Get default address',
    description:
      'Returns the default shipping address for the authenticated user.',
  })
  @ApiResponse({
    status: 200,
    description: 'Default address retrieved',
  })
  @ApiResponse({
    status: 404,
    description: 'No default address found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async getDefaultAddress(@Request() req) {
    return this.ordersService.getDefaultAddress(req.user.userId);
  }

  @Put('addresses/:addressId/default')
  @ApiOperation({
    summary: 'Set default address',
    description:
      'Sets a specific address as the default for the authenticated user.',
  })
  @ApiParam({
    name: 'addressId',
    description: 'Address UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Default address updated successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Address not found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async setDefaultAddress(
    @Request() req,
    @Param('addressId', ParseUUIDPipe) addressId: string,
  ) {
    return this.ordersService.setDefaultAddress(req.user.userId, addressId);
  }

  @Delete('addresses/:addressId')
  @ApiOperation({
    summary: 'Delete address',
    description: 'Deletes a shipping address for the authenticated user.',
  })
  @ApiParam({
    name: 'addressId',
    description: 'Address UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Address deleted successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Address not found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
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
  @ApiOperation({
    summary: 'Get shopping cart',
    description:
      'Returns the current shopping cart for the authenticated user.',
  })
  @ApiResponse({
    status: 200,
    description: 'Cart retrieved successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async getCart(@Request() req) {
    return this.ordersService.getCart(req.user.userId);
  }

  @Post('cart')
  @ApiOperation({
    summary: 'Add to cart',
    description: "Adds a product variant to the user's shopping cart.",
  })
  @ApiBody({ type: AddToCartDto })
  @ApiResponse({
    status: 201,
    description: 'Item added to cart successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid data or insufficient stock',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async addToCart(@Request() req, @Body() addToCartDto: AddToCartDto) {
    return this.ordersService.addToCart(req.user.userId, addToCartDto);
  }

  @Put('cart/:itemId')
  @ApiOperation({
    summary: 'Update cart item quantity',
    description:
      'Updates the quantity of a specific item in the shopping cart.',
  })
  @ApiParam({
    name: 'itemId',
    description: 'Cart item UUID',
    example: '550e8400-e29b-41d4-a716-446655440002',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        quantity: {
          type: 'number',
          description: 'New quantity',
          example: 3,
          minimum: 1,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Cart item updated successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Cart item not found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async updateCartItem(
    @Request() req,
    @Param('itemId', ParseUUIDPipe) itemId: string,
    @Body('quantity') quantity: number,
  ) {
    if (!quantity || quantity < 1) {
      throw new BadRequestException('Quantity must be at least 1');
    }
    return this.ordersService.updateCartItem(req.user.userId, itemId, quantity);
  }

  @Delete('cart/:itemId')
  @ApiOperation({
    summary: 'Remove item from cart',
    description: 'Removes a specific item from the shopping cart.',
  })
  @ApiParam({
    name: 'itemId',
    description: 'Cart item UUID',
    example: '550e8400-e29b-41d4-a716-446655440002',
  })
  @ApiResponse({
    status: 200,
    description: 'Item removed from cart successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Cart item not found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async removeCartItem(
    @Request() req,
    @Param('itemId', ParseUUIDPipe) itemId: string,
  ) {
    return this.ordersService.removeCartItem(req.user.userId, itemId);
  }

  @Delete('cart')
  @ApiOperation({
    summary: 'Clear cart',
    description: 'Removes all items from the shopping cart.',
  })
  @ApiResponse({
    status: 200,
    description: 'Cart cleared successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async clearCart(@Request() req) {
    return this.ordersService.clearCart(req.user.userId);
  }

  // ==========================================
  // 3. ORDER ENDPOINTS
  // ==========================================

  @Post()
  @ApiOperation({
    summary: 'Create a new order',
    description: "Creates a new order from the user's cart or specified items.",
  })
  @ApiBody({ type: CreateOrderDto })
  @ApiResponse({
    status: 201,
    description: 'Order created successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid order data or insufficient stock',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async createOrder(@Request() req, @Body() createOrderDto: CreateOrderDto) {
    return this.ordersService.createOrder(req.user.userId, createOrderDto);
  }

  @Get()
  @ApiOperation({
    summary: 'Get user orders',
    description:
      'Returns all orders for the authenticated user. Can filter by status.',
  })
  @ApiQuery({
    name: 'status',
    required: false,
    description: 'Filter orders by status',
    enum: [
      'PENDING',
      'CONFIRMED',
      'PROCESSING',
      'SHIPPED',
      'DELIVERED',
      'CANCELLED',
    ],
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'Page number',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Items per page',
  })
  @ApiResponse({
    status: 200,
    description: 'Orders retrieved successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async getOrders(
    @Request() req,
    @Query('status') status?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number = 10,
  ) {
    return this.ordersService.getOrders(req.user.userId, status, page, limit);
  }

  @Post(':id/payment')
  @ApiOperation({
    summary: 'Process payment',
    description:
      'Processes payment for an order using the specified payment method.',
  })
  @ApiParam({
    name: 'id',
    description: 'Order UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiBody({ type: ProcessPaymentDto })
  @ApiResponse({
    status: 200,
    description: 'Payment processed successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid payment data',
  })
  @ApiResponse({
    status: 404,
    description: 'Order not found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async processPayment(
    @Request() req,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() paymentData: ProcessPaymentDto,
  ) {
    return this.ordersService.processPayment(id, req.user.userId, paymentData);
  }

  // ==========================================
  // 4. DYNAMIC ORDER ROUTES (MUST BE LAST!)
  // ==========================================

  @Get(':id')
  @ApiOperation({
    summary: 'Get order by ID',
    description: 'Returns a specific order by its UUID.',
  })
  @ApiParam({
    name: 'id',
    description: 'Order UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Order found',
  })
  @ApiResponse({
    status: 404,
    description: 'Order not found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async getOrderById(@Request() req, @Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.getOrderById(id, req.user.userId);
  }

  @Put(':id/status')
  @ApiOperation({
    summary: 'Update order status',
    description: 'Updates the status of an order.',
  })
  @ApiParam({
    name: 'id',
    description: 'Order UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
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
          example: 'PROCESSING',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Order status updated successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Order not found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async updateOrderStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('status') status: string,
  ) {
    return this.ordersService.updateOrderStatus(id, status);
  }
}
