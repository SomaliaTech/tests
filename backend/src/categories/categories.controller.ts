import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Query,
  ParseUUIDPipe,
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
import { DrizzleService } from '../drizzle/drizzle.service';
import { categories, products, mediaAssets } from '../drizzle/schema';
import { CreateCategoryDto } from './dto/create-category.dto';
import { eq, isNull, inArray } from 'drizzle-orm';
import { randomUUID } from 'crypto';

@ApiTags('categories')
@Controller('categories')
export class CategoriesController {
  constructor(private drizzle: DrizzleService) {}

  @Post()
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Create a new category',
    description: 'Creates a new product category. Requires authentication.',
  })
  @ApiBody({ type: CreateCategoryDto })
  @ApiResponse({ status: 201, description: 'Category created successfully' })
  @ApiResponse({ status: 400, description: 'Invalid category data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async create(@Body() createCategoryDto: CreateCategoryDto) {
    const id = randomUUID();
    const [category] = await this.drizzle.db
      .insert(categories)
      .values({
        id: id,
        name: createCategoryDto.name,
        slug: createCategoryDto.slug,
        description: createCategoryDto.description,
        parentId: createCategoryDto.parentId || null,
        iconId: createCategoryDto.iconId || null,
      })
      .returning();
    return category;
  }

  @Get()
  @ApiOperation({
    summary: 'Get all categories',
    description:
      'Returns a list of all categories including parent and subcategories.',
  })
  @ApiResponse({
    status: 200,
    description: 'Categories retrieved successfully',
  })
  async findAll() {
    const allCategories = await this.drizzle.db.select().from(categories);
    return this._formatCategoriesWithIcons(allCategories);
  }

  @Get('parents')
  @ApiOperation({
    summary: 'Get parent categories',
    description:
      'Returns all root/parent categories (categories with no parent).',
  })
  @ApiResponse({
    status: 200,
    description: 'Parent categories retrieved successfully',
  })
  async getParentCategories() {
    const parentCategories = await this.drizzle.db
      .select()
      .from(categories)
      .where(isNull(categories.parentId));
    return this._formatCategoriesWithIcons(parentCategories);
  }

  @Get('sub/:parentId')
  @ApiOperation({
    summary: 'Get subcategories',
    description: 'Returns all subcategories belonging to a parent category.',
  })
  @ApiParam({ name: 'parentId', description: 'Parent category UUID' })
  @ApiResponse({
    status: 200,
    description: 'Subcategories retrieved successfully',
  })
  @ApiResponse({ status: 404, description: 'Parent category not found' })
  async getSubcategories(@Param('parentId', ParseUUIDPipe) parentId: string) {
    const subcategories = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.parentId, parentId));
    return this._formatCategoriesWithIcons(subcategories);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get category by ID',
    description: 'Returns a category by its UUID.',
  })
  @ApiParam({ name: 'id', description: 'Category UUID' })
  @ApiResponse({ status: 200, description: 'Category found' })
  @ApiResponse({ status: 404, description: 'Category not found' })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const [category] = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, id));
    if (!category) return null;
    const [formatted] = await this._formatCategoriesWithIcons([category]);
    return formatted;
  }

  // ✅ UPDATED: Delete with optional transfer
  @Delete(':id')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Delete category',
    description:
      'Deletes a category. Use transferToId query param to move products first.',
  })
  @ApiParam({ name: 'id', description: 'Category UUID' })
  @ApiQuery({
    name: 'transferToId',
    required: false,
    description: 'Target category ID to transfer products to',
  })
  @ApiResponse({ status: 200, description: 'Category deleted successfully' })
  @ApiResponse({
    status: 400,
    description: 'Cannot delete category with products',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Category not found' })
  async remove(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('transferToId') transferToId?: string,
  ) {
    // ✅ Check if category exists
    const [category] = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, id));

    if (!category) {
      throw new BadRequestException('Category not found');
    }

    // ✅ Check if category has subcategories
    const subcategories = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.parentId, id));

    // ✅ Check if category has products
    const categoryProducts = await this.drizzle.db
      .select()
      .from(products)
      .where(eq(products.categoryId, id));

    const hasSubcategories = subcategories.length > 0;
    const hasProducts = categoryProducts.length > 0;

    // ✅ If no products and no subcategories, just delete
    if (!hasProducts && !hasSubcategories) {
      const [deleted] = await this.drizzle.db
        .delete(categories)
        .where(eq(categories.id, id))
        .returning();
      return { message: 'Category deleted successfully', category: deleted };
    }

    // ✅ If has products/subcategories AND transferToId is provided, do the transfer
    if (transferToId) {
      // Validate target category exists
      const [targetCategory] = await this.drizzle.db
        .select()
        .from(categories)
        .where(eq(categories.id, transferToId));

      if (!targetCategory) {
        throw new BadRequestException('Target category not found');
      }

      // Prevent transferring to itself
      if (transferToId === id) {
        throw new BadRequestException('Cannot transfer to the same category');
      }

      // ✅ Transfer products to target category
      if (hasProducts) {
        await this.drizzle.db
          .update(products)
          .set({ categoryId: transferToId })
          .where(eq(products.categoryId, id));
      }

      // ✅ Transfer subcategories to target category
      if (hasSubcategories) {
        await this.drizzle.db
          .update(categories)
          .set({ parentId: transferToId })
          .where(eq(categories.parentId, id));
      }

      // ✅ Now delete the category
      const [deleted] = await this.drizzle.db
        .delete(categories)
        .where(eq(categories.id, id))
        .returning();

      return {
        message: `Category deleted. ${hasProducts ? categoryProducts.length : 0} products and ${hasSubcategories ? subcategories.length : 0} subcategories transferred.`,
        category: deleted,
      };
    }

    // ✅ If has products/subcategories but no transferToId, reject
    throw new BadRequestException(
      `Cannot delete category with ${hasProducts ? categoryProducts.length : 0} products and ${hasSubcategories ? subcategories.length : 0} subcategories. Use transferToId query parameter to move them first.`,
    );
  }

  // ✅ Helper method to attach iconUrl to categories
  private async _formatCategoriesWithIcons(categoryList: any[]) {
    if (!categoryList || categoryList.length === 0) return categoryList;

    const iconIds = categoryList.filter((c) => c.iconId).map((c) => c.iconId);

    let iconMap = new Map<string, string>();

    if (iconIds.length > 0) {
      const icons = await this.drizzle.db
        .select({
          id: mediaAssets.id,
          url: mediaAssets.url,
        })
        .from(mediaAssets)
        .where(inArray(mediaAssets.id, iconIds));

      iconMap = new Map(icons.map((icon) => [icon.id, icon.url]));
    }

    return categoryList.map((category) => ({
      ...category,
      iconUrl: category.iconId ? iconMap.get(category.iconId) || null : null,
    }));
  }
}
