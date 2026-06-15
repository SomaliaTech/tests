import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  ParseUUIDPipe,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { categories } from '../drizzle/schema';
import { CreateCategoryDto } from './dto/create-category.dto';
import { eq, isNull } from 'drizzle-orm';
import { randomUUID } from 'crypto'; // Native Node.js module (No install needed)

@Controller('categories')
export class CategoriesController {
  constructor(private drizzle: DrizzleService) {}

  @Post()
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
  async findAll() {
    return this.drizzle.db.select().from(categories);
  }

  // Add this endpoint for parent categories
  @Get('parents')
  async getParentCategories() {
    return this.drizzle.db
      .select()
      .from(categories)
      .where(isNull(categories.parentId));
  }

  @Get('sub/:parentId')
  async getSubcategories(@Param('parentId', ParseUUIDPipe) parentId: string) {
    return this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.parentId, parentId));
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const [category] = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, id));

    return category;
  }

  @Delete(':id')
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    const [deletedCategory] = await this.drizzle.db
      .delete(categories)
      .where(eq(categories.id, id))
      .returning();

    return deletedCategory;
  }
}
