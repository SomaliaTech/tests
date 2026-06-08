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
import { eq } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

@Controller('categories')
export class CategoriesController {
  constructor(private drizzle: DrizzleService) {}

  @Post()
  async create(@Body() createCategoryDto: CreateCategoryDto) {
    const [category] = await this.drizzle.db
      .insert(categories)
      .values({
        id: uuidv4(),
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
