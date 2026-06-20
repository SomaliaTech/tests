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
import { categories } from '../drizzle/schema';
import { CreateCategoryDto } from './dto/create-category.dto';
import { eq, isNull } from 'drizzle-orm';
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
    schema: {
      example: {
        id: '550e8400-e29b-41d4-a716-446655440000',
        name: 'Electronics',
        slug: 'electronics',
        description: 'Electronic devices and gadgets',
        parentId: null,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      },
    },
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid category data',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - Invalid or missing JWT token',
  })
  async create(@Body() createCategoryDto: CreateCategoryDto) {
    const id = randomUUID();
    const [category] = await this.drizzle.db
      .insert(categories)
      .values({
        id: id,
        name: createCategoryDto.name,
        slug: createCategoryDto.slug,
        description: createCategoryDto.description,
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
    schema: {
      example: [
        {
          id: '550e8400-e29b-41d4-a716-446655440000',
          name: 'Electronics',
          slug: 'electronics',
          description: 'Electronic devices',
          parentId: null,
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z',
        },
      ],
    },
  })
  async findAll() {
    return this.drizzle.db.select().from(categories);
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
    return this.drizzle.db
      .select()
      .from(categories)
      .where(isNull(categories.parentId));
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
  @ApiResponse({
    status: 404,
    description: 'Parent category not found',
  })
  async getSubcategories(@Param('parentId', ParseUUIDPipe) parentId: string) {
    return this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.parentId, parentId));
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
  @ApiResponse({
    status: 200,
    description: 'Category found',
  })
  @ApiResponse({
    status: 404,
    description: 'Category not found',
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const [category] = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, id));

    return category;
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
  @ApiResponse({
    status: 200,
    description: 'Category deleted successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - Invalid or missing JWT token',
  })
  @ApiResponse({
    status: 404,
    description: 'Category not found',
  })
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    const [deletedCategory] = await this.drizzle.db
      .delete(categories)
      .where(eq(categories.id, id))
      .returning();

    return deletedCategory;
  }
}
