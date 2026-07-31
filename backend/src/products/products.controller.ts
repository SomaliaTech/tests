// products.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  ParseUUIDPipe,
  Query,
  UseGuards,
  Request,
  Put,
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
import {
  CreateProductDto,
  CreateProductVariantDto,
  UploadBase64ImageDto,
  ProductResponseDto,
  PaginatedProductsResponseDto,
  ProductFiltersDto,
} from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { ProductsService } from './products.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard, Permissions } from '../auth/guards/permission.guard';

import { Permission } from '../admin/enums/permissions.enum';
import { AddToCartDto, UpdateCartItemQuantityDto } from './dto/cart.dto';

@ApiTags('products')
@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  // ==========================================
  // HELPER METHOD - Transform product to DTO
  // ==========================================

  private transformProduct(product: any): ProductResponseDto {
    return {
      ...product,
      slug: product.slug || '',
      rating: Number(product.rating) || 0,
      reviewCount: Number(product.reviewCount) || 0,
    };
  }

  private transformProducts(products: any[]): ProductResponseDto[] {
    return products.map((p) => this.transformProduct(p));
  }

  private transformPaginatedResponse(
    result: any,
  ): PaginatedProductsResponseDto {
    return {
      ...result,
      products: this.transformProducts(result.products),
    };
  }

  // ==========================================
  // ADMIN ENDPOINTS - Permission Protected
  // ==========================================

  // CREATE PRODUCT - Requires PRODUCT_CREATE permission
  @Post()
  @UseGuards(JwtAuthGuard, PermissionGuard)
  @Permissions(Permission.PRODUCT_CREATE)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Create a new product (Admin)',
    description:
      'Creates a new product. Requires authentication and PRODUCT_CREATE permission.',
  })
  @ApiBody({ type: CreateProductDto })
  @ApiResponse({
    status: 201,
    description: 'Product created successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - Invalid or missing JWT token',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Requires PRODUCT_CREATE permission',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid product data',
  })
  create(@Body() createProductDto: CreateProductDto) {
    return this.productsService.create(createProductDto);
  }

  // UPLOAD IMAGES FROM URLS - Requires PRODUCT_UPDATE permission
  @Post(':id/images/urls')
  @UseGuards(JwtAuthGuard, PermissionGuard)
  @Permissions(Permission.PRODUCT_UPDATE)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Upload product images from URLs (Admin)',
    description:
      'Adds product images using public image URLs. Requires PRODUCT_UPDATE permission.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        imageUrls: {
          type: 'array',
          items: { type: 'string' },
          example: [
            'https://example.com/image1.jpg',
            'https://example.com/image2.jpg',
          ],
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Images uploaded successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Requires PRODUCT_UPDATE permission',
  })
  uploadImagesFromUrls(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: { imageUrls: string[] },
  ) {
    if (
      !body.imageUrls ||
      !Array.isArray(body.imageUrls) ||
      body.imageUrls.length === 0
    ) {
      throw new BadRequestException('imageUrls array is required');
    }
    return this.productsService.uploadImagesFromUrls(id, body.imageUrls);
  }

  // UPLOAD BASE64 IMAGE - Requires PRODUCT_UPDATE permission
  @Post(':id/images/base64')
  @UseGuards(JwtAuthGuard, PermissionGuard)
  @Permissions(Permission.PRODUCT_UPDATE)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Upload product image as Base64 (Admin)',
    description:
      'Adds a product image using a Base64 encoded string. Requires PRODUCT_UPDATE permission.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiBody({ type: UploadBase64ImageDto })
  @ApiResponse({
    status: 200,
    description: 'Image uploaded successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Requires PRODUCT_UPDATE permission',
  })
  uploadBase64Image(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() base64Dto: UploadBase64ImageDto,
  ) {
    return this.productsService.uploadBase64Image(id, base64Dto);
  }

  // ADD VARIANT - Requires PRODUCT_UPDATE permission
  @Post(':id/variants')
  @UseGuards(JwtAuthGuard, PermissionGuard)
  @Permissions(Permission.PRODUCT_UPDATE)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Add product variant (Admin)',
    description:
      'Adds a new variant to an existing product. Requires PRODUCT_UPDATE permission.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiBody({ type: CreateProductVariantDto })
  @ApiResponse({
    status: 201,
    description: 'Variant added successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Requires PRODUCT_UPDATE permission',
  })
  addVariant(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() createVariantDto: CreateProductVariantDto,
  ) {
    return this.productsService.addVariant(id, createVariantDto);
  }

  // UPDATE PRODUCT - Requires PRODUCT_UPDATE permission
  @Patch(':id')
  @UseGuards(JwtAuthGuard, PermissionGuard)
  @Permissions(Permission.PRODUCT_UPDATE)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update product (Admin)',
    description:
      'Updates an existing product. Requires PRODUCT_UPDATE permission.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiBody({ type: UpdateProductDto })
  @ApiResponse({
    status: 200,
    description: 'Product updated successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Requires PRODUCT_UPDATE permission',
  })
  @ApiResponse({
    status: 404,
    description: 'Product not found',
  })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateProductDto: UpdateProductDto,
  ) {
    return this.productsService.update(id, updateProductDto);
  }

  // DELETE IMAGE - Requires PRODUCT_UPDATE permission
  @Delete(':id/images/:imageId')
  @UseGuards(JwtAuthGuard, PermissionGuard)
  @Permissions(Permission.PRODUCT_UPDATE)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Delete product image (Admin)',
    description:
      'Removes an image from a product. Requires PRODUCT_UPDATE permission.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiParam({
    name: 'imageId',
    description: 'Image UUID',
    example: '550e8400-e29b-41d4-a716-446655440001',
  })
  @ApiResponse({
    status: 200,
    description: 'Image deleted successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Requires PRODUCT_UPDATE permission',
  })
  deleteImage(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('imageId', ParseUUIDPipe) imageId: string,
  ) {
    return this.productsService.deleteImage(id, imageId);
  }

  // DELETE PRODUCT - Requires PRODUCT_DELETE permission
  @Delete(':id')
  @UseGuards(JwtAuthGuard, PermissionGuard)
  @Permissions(Permission.PRODUCT_DELETE)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Delete product (Admin)',
    description:
      'Permanently deletes a product. Requires PRODUCT_DELETE permission.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Product deleted successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Requires PRODUCT_DELETE permission',
  })
  @ApiResponse({
    status: 404,
    description: 'Product not found',
  })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.productsService.remove(id);
  }

  // UPDATE VARIANT STOCK - Requires PRODUCT_UPDATE permission
  @Patch('variants/:variantId/stock')
  @UseGuards(JwtAuthGuard, PermissionGuard)
  @Permissions(Permission.PRODUCT_UPDATE)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update variant stock (Admin)',
    description:
      'Updates the stock quantity of a specific product variant. Requires PRODUCT_UPDATE permission.',
  })
  @ApiParam({
    name: 'variantId',
    description: 'Variant UUID',
    example: '550e8400-e29b-41d4-a716-446655440002',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        quantity: {
          type: 'number',
          description: 'New stock quantity',
          example: 50,
          minimum: 0,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Stock updated successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Requires PRODUCT_UPDATE permission',
  })
  @ApiResponse({
    status: 404,
    description: 'Variant not found',
  })
  updateVariantStock(
    @Param('variantId', ParseUUIDPipe) variantId: string,
    @Body('quantity') quantity: number,
  ) {
    if (quantity < 0) {
      throw new BadRequestException('Quantity cannot be negative');
    }
    return this.productsService.updateVariantStock(variantId, quantity);
  }

  // ==========================================
  // PUBLIC ENDPOINTS - No Authentication Required
  // ==========================================

  // GET ALL PRODUCTS - Public
  @Get()
  @ApiOperation({
    summary: 'Get all products (Public)',
    description:
      'Returns a list of all products with pagination. No authentication required.',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'sortBy',
    required: false,
    enum: ['price_asc', 'price_desc', 'newest', 'discount_desc'],
  })
  @ApiQuery({ name: 'minPrice', required: false, type: Number })
  @ApiQuery({ name: 'maxPrice', required: false, type: Number })
  @ApiQuery({ name: 'categoryId', required: false })
  @ApiResponse({
    status: 200,
    description: 'Products retrieved successfully',
    type: PaginatedProductsResponseDto,
  })
  async findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('sortBy') sortBy?: string,
    @Query('minPrice') minPrice?: string,
    @Query('maxPrice') maxPrice?: string,
    @Query('categoryId') categoryId?: string,
  ): Promise<PaginatedProductsResponseDto> {
    const result = await this.productsService.findAll({
      page: Math.max(1, page),
      limit: Math.min(50, limit),
      sortBy,
      minPrice: minPrice ? parseFloat(minPrice) : undefined,
      maxPrice: maxPrice ? parseFloat(maxPrice) : undefined,
      categoryId,
    });

    return this.transformPaginatedResponse(result);
  }

  // SEARCH PRODUCTS - Public
  @Get('search')
  @ApiOperation({
    summary: 'Search products (Public)',
    description: 'Search products with filters, sorting, and pagination.',
  })
  @ApiQuery({
    name: 'q',
    required: false,
    description: 'Search term',
    example: 'iphone',
  })
  @ApiQuery({
    name: 'categoryId',
    required: false,
    description: 'Filter by category UUID',
  })
  @ApiQuery({
    name: 'minPrice',
    required: false,
    description: 'Minimum price filter',
    example: '100',
  })
  @ApiQuery({
    name: 'maxPrice',
    required: false,
    description: 'Maximum price filter',
    example: '2000',
  })
  @ApiQuery({
    name: 'brand',
    required: false,
    description: 'Filter by brand',
    example: 'Apple',
  })
  @ApiQuery({
    name: 'sortBy',
    required: false,
    description: 'Sort by field',
    enum: ['price_asc', 'price_desc', 'newest', 'popular'],
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
    description: 'Number of items per page',
  })
  @ApiResponse({
    status: 200,
    description: 'Products found',
    type: PaginatedProductsResponseDto,
  })
  async searchProducts(
    @Query('q') searchTerm?: string,
    @Query('categoryId') categoryId?: string,
    @Query('minPrice') minPrice?: string,
    @Query('maxPrice') maxPrice?: string,
    @Query('brand') brand?: string,
    @Query('sortBy') sortBy?: 'price_asc' | 'price_desc' | 'newest' | 'popular',
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ): Promise<PaginatedProductsResponseDto> {
    const result = await this.productsService.searchProducts(searchTerm || '', {
      categoryId,
      minPrice: minPrice ? parseFloat(minPrice) : undefined,
      maxPrice: maxPrice ? parseFloat(maxPrice) : undefined,
      brand,
      sortBy,
      page: Math.max(1, page),
      limit: Math.min(50, limit),
    });

    return this.transformPaginatedResponse(result);
  }

  // GET FILTERS - Public
  @Get('filters')
  @ApiOperation({
    summary: 'Get product filters (Public)',
    description:
      'Returns available product filters including price range and categories.',
  })
  @ApiResponse({
    status: 200,
    description: 'Filters retrieved successfully',
  })
  async getFilters() {
    return this.productsService.getProductFilters();
  }

  // GET FEATURED PRODUCTS - Public
  @Get('featured')
  @ApiOperation({
    summary: 'Get featured products (Public)',
    description: 'Returns a list of featured products.',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Number of featured products to return',
  })
  @ApiResponse({
    status: 200,
    description: 'Featured products retrieved successfully',
    type: [ProductResponseDto],
  })
  async getFeatured(
    @Query('limit', new DefaultValuePipe(6), ParseIntPipe) limit: number = 6,
  ): Promise<ProductResponseDto[]> {
    const products = await this.productsService.getFeaturedProducts(
      Math.min(limit, 20),
    );
    return this.transformProducts(products);
  }

  // DEBUG CATEGORY - Public
  @Get('debug/category/:categoryId')
  @ApiOperation({
    summary: 'Debug category products (Public)',
    description: 'Returns debug information about products in a category.',
  })
  @ApiParam({
    name: 'categoryId',
    description: 'Category UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Debug information retrieved',
  })
  async debugCategory(@Param('categoryId', ParseUUIDPipe) categoryId: string) {
    return this.productsService.debugCategory(categoryId);
  }

  // GET PRODUCT BY SLUG - Public
  @Get('slug/:slug')
  @ApiOperation({
    summary: 'Get product by slug (Public)',
    description: 'Returns a product by its unique slug.',
  })
  @ApiParam({
    name: 'slug',
    description: 'Product slug',
    example: 'iphone-15-pro-max',
  })
  @ApiResponse({
    status: 200,
    description: 'Product found',
    type: ProductResponseDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Product not found',
  })
  async findBySlug(@Param('slug') slug: string): Promise<ProductResponseDto> {
    const product = await this.productsService.findBySlug(slug);
    return this.transformProduct(product);
  }

  // GET PRODUCTS BY CATEGORY - Public
  @Get('category/:categoryId')
  @ApiOperation({
    summary: 'Get products by category (Public)',
    description:
      'Returns products belonging to a specific category with filters.',
  })
  @ApiParam({
    name: 'categoryId',
    description: 'Category UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
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
  @ApiQuery({
    name: 'sortBy',
    required: false,
    enum: ['price_asc', 'price_desc', 'newest', 'popular'],
  })
  @ApiQuery({
    name: 'minPrice',
    required: false,
    type: Number,
    description: 'Minimum price',
  })
  @ApiQuery({
    name: 'maxPrice',
    required: false,
    type: Number,
    description: 'Maximum price',
  })
  @ApiResponse({
    status: 200,
    description: 'Products retrieved successfully',
    type: PaginatedProductsResponseDto,
  })
  async getByCategory(
    @Param('categoryId', ParseUUIDPipe) categoryId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('sortBy') sortBy?: string,
    @Query('minPrice') minPrice?: string,
    @Query('maxPrice') maxPrice?: string,
  ): Promise<PaginatedProductsResponseDto> {
    const result = await this.productsService.getProductsByCategory(
      categoryId,
      {
        page: Math.max(1, page),
        limit: Math.min(50, limit),
        sortBy,
        minPrice: minPrice ? parseFloat(minPrice) : undefined,
        maxPrice: maxPrice ? parseFloat(maxPrice) : undefined,
      },
    );

    return this.transformPaginatedResponse(result);
  }

  // GET PRODUCT BY ID - Public
  @Get(':id')
  @ApiOperation({
    summary: 'Get product by ID (Public)',
    description: 'Returns a product by its UUID.',
  })
  @ApiParam({
    name: 'id',
    description: 'Product UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Product found',
    type: ProductResponseDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Product not found',
  })
  async findOne(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ProductResponseDto> {
    const product = await this.productsService.findOne(id);
    return this.transformProduct(product);
  }

  // ==========================================
  // CART ENDPOINTS - JWT Authentication Only
  // ==========================================

  @Post('cart')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Add item to cart',
    description: "Adds a product variant to the user's cart.",
  })
  @ApiBody({ type: AddToCartDto })
  @ApiResponse({
    status: 200,
    description: 'Item added to cart successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid input or insufficient stock',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async addToCart(@Request() req, @Body() addToCartDto: AddToCartDto) {
    const userId = req.user.userId || req.user.sub;
    return this.productsService.addToCart(userId, addToCartDto);
  }

  @Put('cart/:itemId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update cart item quantity',
    description: 'Updates the quantity of a specific cart item.',
  })
  @ApiParam({
    name: 'itemId',
    description: 'Cart item ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiBody({ type: UpdateCartItemQuantityDto })
  @ApiResponse({
    status: 200,
    description: 'Cart item updated successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid input or insufficient stock',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 404,
    description: 'Cart item not found',
  })
  async updateCartItem(
    @Request() req,
    @Param('itemId', ParseUUIDPipe) itemId: string,
    @Body() updateCartItemDto: UpdateCartItemQuantityDto,
  ) {
    const userId = req.user.userId || req.user.sub;
    return this.productsService.updateCartItem(
      userId,
      itemId,
      updateCartItemDto.quantity,
    );
  }

  @Delete('cart/:itemId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Remove item from cart',
    description: 'Removes a specific item from the cart.',
  })
  @ApiParam({
    name: 'itemId',
    description: 'Cart item ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Item removed from cart',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 404,
    description: 'Cart item not found',
  })
  async removeCartItem(
    @Request() req,
    @Param('itemId', ParseUUIDPipe) itemId: string,
  ) {
    const userId = req.user.userId || req.user.sub;
    return this.productsService.removeCartItem(userId, itemId);
  }

  @Get('cart')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get cart',
    description: "Retrieves the current user's cart.",
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
    const userId = req.user.userId || req.user.sub;
    return this.productsService.getCartItems(userId);
  }

  @Delete('cart')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Clear cart',
    description: "Removes all items from the user's cart.",
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
    const userId = req.user.userId || req.user.sub;
    return this.productsService.clearCart(userId);
  }
}
