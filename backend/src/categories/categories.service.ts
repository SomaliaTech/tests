import { Injectable, NotFoundException } from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { categories } from '../drizzle/schema';
import { eq, isNull } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class CategoriesService {
  constructor(private drizzle: DrizzleService) {}

  async createCategory(data: {
    name: string;
    slug: string;
    description?: string;
    parentId?: string;
  }) {
    const [category] = await this.drizzle.db
      .insert(categories)
      .values({
        id: uuidv4(),
        name: data.name,
        slug: data.slug,
        description: data.description || null,
        parentId: data.parentId || null,
      })
      .returning();

    return category;
  }

  async getAllCategories() {
    return this.drizzle.db.select().from(categories);
  }

  async getParentCategories() {
    return (
      this.drizzle.db
        .select()
        .from(categories)
        // ✅ FIX: Use isNull() instead of eq(..., null)
        .where(isNull(categories.parentId))
    );
  }

  async getSubcategories(parentId: string) {
    return this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.parentId, parentId));
  }

  async getCategoryWithSubcategories(categoryId: string) {
    const category = await this.drizzle.db.query.categories.findFirst({
      where: eq(categories.id, categoryId),
      with: {
        children: true,
      },
    });

    if (!category) {
      throw new NotFoundException('Category not found');
    }

    return category;
  }

  async getCategoryTree() {
    const allCategories = await this.getAllCategories();
    const categoryMap = new Map();
    const roots: any[] = []; // ✅ FIX: Added explicit 'any[]' type here

    // First, create a map of all categories
    allCategories.forEach((category) => {
      categoryMap.set(category.id, { ...category, children: [] });
    });

    // Then, build the tree
    allCategories.forEach((category) => {
      const node = categoryMap.get(category.id);
      if (category.parentId && categoryMap.has(category.parentId)) {
        const parent = categoryMap.get(category.parentId);
        if (parent) {
          parent.children.push(node);
        }
      } else {
        roots.push(node);
      }
    });

    return roots;
  }

  async getCategoryById(id: string) {
    const [category] = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, id));

    if (!category) {
      throw new NotFoundException('Category not found');
    }

    return category;
  }

  async getCategoryBySlug(slug: string) {
    const [category] = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.slug, slug));

    if (!category) {
      throw new NotFoundException('Category not found');
    }

    return category;
  }
}
