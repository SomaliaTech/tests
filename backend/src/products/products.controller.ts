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
  CreateProductDto,
  CreateProductVariantDto,
  UploadBase64ImageDto,
} from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { ProductsService } from './products.service';
import { SearchProductDto } from './dto/search-product.dto';

@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Post()
  create(@Body() createProductDto: CreateProductDto) {
    return this.productsService.create(createProductDto);
  }

  // ========================================================
  // ✨ STATIC GET ENDPOINTS (Must stay on top)
  // ========================================================

  @Get()
  findAll() {
    return this.productsService.findAll();
  }

  @Get('search')
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
  async getFilters() {
    return this.productsService.getProductFilters();
  }

  @Get('featured')
  async getFeatured(@Query('limit') limit?: string) {
    return this.productsService.getFeaturedProducts(
      limit ? parseInt(limit) : 10,
    );
  }

  // ========================================================
  // ⚡ DYNAMIC/PARAMETERIZED ENDPOINTS (Must stay on bottom)
  // ========================================================

  @Get('slug/:slug')
  findBySlug(@Param('slug') slug: string) {
    return this.productsService.findBySlug(slug);
  }

  @Get('category/:categoryId')
  async getByCategory(
    @Param('categoryId', ParseUUIDPipe) categoryId: string,
    @Query() filters: any,
  ) {
    return this.productsService.getProductsByCategory(categoryId, filters);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.productsService.findOne(id);
  }

  @Post(':id/images/urls')
  uploadImagesFromUrls(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: { imageUrls: string[] },
  ) {
    return this.productsService.uploadImagesFromUrls(id, body.imageUrls);
  }

  @Post(':id/images/base64')
  uploadBase64Image(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() base64Dto: UploadBase64ImageDto,
  ) {
    return this.productsService.uploadBase64Image(id, base64Dto);
  }

  @Post(':id/variants')
  addVariant(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() createVariantDto: CreateProductVariantDto,
  ) {
    return this.productsService.addVariant(id, createVariantDto);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateProductDto: UpdateProductDto,
  ) {
    return this.productsService.update(id, updateProductDto);
  }

  @Delete(':id/images/:imageId')
  deleteImage(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('imageId', ParseUUIDPipe) imageId: string,
  ) {
    return this.productsService.deleteImage(id, imageId);
  }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.productsService.remove(id);
  }

  @Patch('variants/:variantId/stock')
  updateVariantStock(
    @Param('variantId', ParseUUIDPipe) variantId: string,
    @Body('quantity') quantity: number,
  ) {
    return this.productsService.updateVariantStock(variantId, quantity);
  }
}
