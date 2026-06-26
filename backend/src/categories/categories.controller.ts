import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiBody,
  ApiParam,
} from '@nestjs/swagger';
import { DrizzleService } from '../drizzle/drizzle.service';
import { categories, mediaAssets } from '../drizzle/schema';
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
  @ApiResponse({
    status: 201,
    description: 'Category created successfully',
  })
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
  @ApiParam({
    name: 'parentId',
    description: 'Parent category UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
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
  @ApiParam({
    name: 'id',
    description: 'Category UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({ status: 200, description: 'Category found' })
  @ApiResponse({ status: 404, description: 'Category not found' })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const [category] = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, id));

    if (!category) return null;

    // Format single category with icon
    const [formatted] = await this._formatCategoriesWithIcons([category]);
    return formatted;
  }

  @Delete(':id')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Delete category',
    description: 'Permanently deletes a category. Requires authentication.',
  })
  @ApiParam({
    name: 'id',
    description: 'Category UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({ status: 200, description: 'Category deleted successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Category not found' })
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    const [deletedCategory] = await this.drizzle.db
      .delete(categories)
      .where(eq(categories.id, id))
      .returning();

    return deletedCategory;
  }

  // ✅ Helper method to attach iconUrl to categories
  private async _formatCategoriesWithIcons(categoryList: any[]) {
    if (!categoryList || categoryList.length === 0) return categoryList;

    // Collect all icon IDs
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
