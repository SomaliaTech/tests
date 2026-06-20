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
} from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { ProductsService } from './products.service';
import { SearchProductDto } from './dto/search-product.dto';

@ApiTags('products')
@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Post()
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Create a new product',
    description: 'Creates a new product. Requires authentication.',
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
    status: 400,
    description: 'Invalid product data',
  })
  create(@Body() createProductDto: CreateProductDto) {
    return this.productsService.create(createProductDto);
  }

  @Get()
  @ApiOperation({
    summary: 'Get all products',
    description: 'Returns a list of all products with pagination.',
  })
  @ApiResponse({
    status: 200,
    description: 'Products retrieved successfully',
  })
  findAll() {
    return this.productsService.findAll();
  }

  @Get('search')
  @ApiOperation({
    summary: 'Search products',
    description: 'Search products with filters, sorting, and pagination.',
  })
  @ApiQuery({
    name: 'search',
    required: false,
    description: 'Search term',
    example: 'iphone',
  })
  @ApiQuery({
    name: 'categoryId',
    required: false,
    description: 'Filter by category UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
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
    example: 'price_asc',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    description: 'Page number for pagination',
    example: '1',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    description: 'Number of items per page',
    example: '10',
  })
  @ApiResponse({
    status: 200,
    description: 'Products found',
  })
  async searchProducts(@Query() searchDto: SearchProductDto) {
    return this.productsService.searchProducts(searchDto.search || '', {
      categoryId: searchDto.categoryId,
      minPrice: searchDto.minPrice,
      maxPrice: searchDto.maxPrice,
      brand: searchDto.brand,
      sortBy: searchDto.sortBy,
      page: searchDto.page,
      limit: searchDto.limit,
    });
  }

  @Get('filters')
  @ApiOperation({
    summary: 'Get product filters',
    description:
      'Returns available product filters including price range and categories.',
  })
  @ApiResponse({
    status: 200,
    description: 'Filters retrieved successfully',
    schema: {
      example: {
        priceRange: {
          min: 10,
          max: 2000,
        },
        categories: [
          {
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Electronics',
            count: 25,
          },
        ],
      },
    },
  })
  async getFilters() {
    return this.productsService.getProductFilters();
  }

  @Get('featured')
  @ApiOperation({
    summary: 'Get featured products',
    description: 'Returns a list of featured products.',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    description: 'Number of featured products to return',
    example: '10',
  })
  @ApiResponse({
    status: 200,
    description: 'Featured products retrieved successfully',
  })
  async getFeatured(@Query('limit') limit?: string) {
    return this.productsService.getFeaturedProducts(
      limit ? parseInt(limit) : 10,
    );
  }

  @Get('debug/category/:categoryId')
  @ApiOperation({
    summary: 'Debug category products',
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
    schema: {
      example: {
        directSubcategoriesCount: 2,
        totalProducts: 100,
      },
    },
  })
  async debugCategory(@Param('categoryId', ParseUUIDPipe) categoryId: string) {
    return this.productsService.debugCategory(categoryId);
  }

  @Get('slug/:slug')
  @ApiOperation({
    summary: 'Get product by slug',
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
  })
  @ApiResponse({
    status: 404,
    description: 'Product not found',
  })
  findBySlug(@Param('slug') slug: string) {
    return this.productsService.findBySlug(slug);
  }

  @Get('category/:categoryId')
  @ApiOperation({
    summary: 'Get products by category',
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
    description: 'Page number',
    example: '1',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    description: 'Items per page',
    example: '10',
  })
  @ApiQuery({
    name: 'sortBy',
    required: false,
    description: 'Sort by',
    enum: ['price_asc', 'price_desc', 'newest', 'popular'],
  })
  @ApiQuery({
    name: 'minPrice',
    required: false,
    description: 'Minimum price',
    example: '100',
  })
  @ApiQuery({
    name: 'maxPrice',
    required: false,
    description: 'Maximum price',
    example: '2000',
  })
  @ApiResponse({
    status: 200,
    description: 'Products retrieved successfully',
  })
  async getByCategory(
    @Param('categoryId', ParseUUIDPipe) categoryId: string,
    @Query() filters: any,
  ) {
    return this.productsService.getProductsByCategory(categoryId, filters);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get product by ID',
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
  })
  @ApiResponse({
    status: 404,
    description: 'Product not found',
  })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.productsService.findOne(id);
  }

  @Post(':id/images/urls')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Upload product images (URLs)',
    description: 'Adds product images using public image URLs.',
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
  uploadImagesFromUrls(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: { imageUrls: string[] },
  ) {
    return this.productsService.uploadImagesFromUrls(id, body.imageUrls);
  }

  @Post(':id/images/base64')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Upload product image (Base64)',
    description: 'Adds a product image using a Base64 encoded string.',
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
  uploadBase64Image(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() base64Dto: UploadBase64ImageDto,
  ) {
    return this.productsService.uploadBase64Image(id, base64Dto);
  }

  @Post(':id/variants')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Add product variant',
    description: 'Adds a new variant to an existing product.',
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
  addVariant(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() createVariantDto: CreateProductVariantDto,
  ) {
    return this.productsService.addVariant(id, createVariantDto);
  }

  @Patch(':id')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update product',
    description: 'Updates an existing product.',
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
    status: 404,
    description: 'Product not found',
  })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateProductDto: UpdateProductDto,
  ) {
    return this.productsService.update(id, updateProductDto);
  }

  @Delete(':id/images/:imageId')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Delete product image',
    description: 'Removes an image from a product.',
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
  deleteImage(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('imageId', ParseUUIDPipe) imageId: string,
  ) {
    return this.productsService.deleteImage(id, imageId);
  }

  @Delete(':id')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Delete product',
    description: 'Permanently deletes a product.',
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
    status: 404,
    description: 'Product not found',
  })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.productsService.remove(id);
  }

  @Patch('variants/:variantId/stock')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update variant stock',
    description: 'Updates the stock quantity of a specific product variant.',
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
    status: 404,
    description: 'Variant not found',
  })
  updateVariantStock(
    @Param('variantId', ParseUUIDPipe) variantId: string,
    @Body('quantity') quantity: number,
  ) {
    return this.productsService.updateVariantStock(variantId, quantity);
  }
}
