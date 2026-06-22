import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { CloudflareService } from 'src/cloudfare/cloudflare.service';
import { inArray } from 'drizzle-orm';
import {
  CreateProductDto,
  CreateProductVariantDto,
  UploadBase64ImageDto,
} from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import {
  products,
  categories,
  mediaAssets,
  productVariants,
  colors,
  sizes,
} from '../drizzle/schema';
import { eq, and, desc, sql, SQL } from 'drizzle-orm';

interface ProductUpdateShape {
  name?: string;
  slug?: string;
  description?: string;
  price?: number;
  stock?: number;
  isActive?: boolean;
  categoryId?: string;
}

@Injectable()
export class ProductsService {
  constructor(
    private drizzle: DrizzleService,
    private cloudflareService: CloudflareService,
  ) {}

  async create(createProductDto: CreateProductDto) {
    const { categoryId, imageUrls, ...productData } = createProductDto;

    const category = await this.drizzle.db
      .select({ id: categories.id })
      .from(categories)
      .where(eq(categories.id, categoryId))
      .limit(1);

    if (!category.length) {
      throw new NotFoundException(`Category with ID ${categoryId} not found`);
    }

    // 🚀 OPTIMIZATION 1: Generate Slug in 1 Query instead of N Queries
    let slug = productData.slug;
    if (!slug) {
      slug = productData.name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '');

      // Fetch all existing slugs that start with the base slug in ONE query
      const existingSlugs = await this.drizzle.db
        .select({ slug: products.slug })
        .from(products)
        .where(sql`${products.slug} LIKE ${slug + '%'}`);

      const slugSet = new Set(existingSlugs.map((s) => s.slug));

      let finalSlug = slug;
      if (slugSet.has(slug)) {
        let counter = 1;
        while (slugSet.has(`${slug}-${counter}`)) {
          counter++;
        }
        finalSlug = `${slug}-${counter}`;
      }
      slug = finalSlug;
    }

    const [product] = await this.drizzle.db
      .insert(products)
      .values({
        ...productData,
        slug,
        price: productData.price.toString(),
        categoryId,
        isActive: productData.isActive ?? true,
      })
      .returning();

    if (imageUrls && imageUrls.length > 0) {
      await this.uploadImagesFromUrls(product.id, imageUrls);
    }

    return this.findOne(product.id);
  }

  async uploadImagesFromUrls(productId: string, imageUrls: string[]) {
    const product = await this.drizzle.db
      .select({ id: products.id })
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);

    if (!product.length) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    // ✅ Using Cloudflare
    const uploadResults = await Promise.all(
      imageUrls.map((url) =>
        this.cloudflareService.uploadFromUrl(url, 'products'),
      ),
    );

    // 🚀 OPTIMIZATION 2: Batch insert all images in ONE query instead of N queries
    const imagesToInsert = uploadResults.map((result) => ({
      url: result.secure_url,
      publicId: result.public_id,
      productId,
    }));

    const insertedImages = await this.drizzle.db
      .insert(mediaAssets)
      .values(imagesToInsert)
      .returning();

    return insertedImages;
  }

  async uploadBase64Image(productId: string, base64Dto: UploadBase64ImageDto) {
    const product = await this.drizzle.db
      .select({ id: products.id })
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);

    if (!product.length) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    // ✅ Using Cloudflare
    const result = await this.cloudflareService.uploadBase64(
      base64Dto.base64Image,
      'products',
    );

    const [image] = await this.drizzle.db
      .insert(mediaAssets)
      .values({
        url: result.secure_url,
        publicId: result.public_id,
        productId,
      })
      .returning();

    return image;
  }

  async addVariant(
    productId: string,
    createVariantDto: CreateProductVariantDto,
  ) {
    const [product] = await this.drizzle.db
      .select({ id: products.id })
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);
    if (!product)
      throw new NotFoundException(`Product with ID ${productId} not found`);

    const [color] = await this.drizzle.db
      .select({ id: colors.id })
      .from(colors)
      .where(eq(colors.id, createVariantDto.colorId))
      .limit(1);
    if (!color)
      throw new NotFoundException(
        `Color with ID ${createVariantDto.colorId} not found`,
      );

    const [size] = await this.drizzle.db
      .select({ id: sizes.id })
      .from(sizes)
      .where(eq(sizes.id, createVariantDto.sizeId))
      .limit(1);
    if (!size)
      throw new NotFoundException(
        `Size with ID ${createVariantDto.sizeId} not found`,
      );

    const existingVariant = await this.drizzle.db
      .select({ id: productVariants.id })
      .from(productVariants)
      .where(
        and(
          eq(productVariants.productId, productId),
          eq(productVariants.colorId, createVariantDto.colorId),
          eq(productVariants.sizeId, createVariantDto.sizeId),
        ),
      )
      .limit(1);

    if (existingVariant.length) {
      throw new BadRequestException(
        'Variant with this color and size already exists',
      );
    }

    const [variant] = await this.drizzle.db
      .insert(productVariants)
      .values({
        productId,
        colorId: createVariantDto.colorId,
        sizeId: createVariantDto.sizeId,
        sku: createVariantDto.sku,
        stock: createVariantDto.stock,
        price: createVariantDto.price?.toString(),
      })
      .returning();

    return this.findVariantWithRelations(variant.id);
  }

  async findAll() {
    return this.drizzle.db.query.products.findMany({
      where: eq(products.isActive, true),
      with: {
        category: true,
        images: true,
        variants: { with: { color: true, size: true } },
      },
      orderBy: [desc(products.createdAt)],
    });
  }

  async findOne(id: string) {
    const product = await this.drizzle.db.query.products.findFirst({
      where: eq(products.id, id),
      with: {
        category: true,
        images: true,
        variants: { with: { color: true, size: true } },
      },
    });

    if (!product)
      throw new NotFoundException(`Product with ID ${id} not found`);
    return product;
  }

  async findBySlug(slug: string) {
    const product = await this.drizzle.db.query.products.findFirst({
      where: and(eq(products.isActive, true), eq(products.slug, slug)),
      with: {
        category: true,
        images: true,
        variants: { with: { color: true, size: true } },
      },
    });

    if (!product)
      throw new NotFoundException(`Product with slug ${slug} not found`);
    return product;
  }

  async update(id: string, updateProductDto: UpdateProductDto) {
    await this.findOne(id);

    // Cast to strict interface to prevent 'any' inference
    const dto = updateProductDto as unknown as ProductUpdateShape;
    const categoryId = dto.categoryId;

    const updateValues: Record<string, any> = { updatedAt: new Date() };

    // ✅ FIXED: All member accesses are now strictly typed
    if (dto.name !== undefined) updateValues.name = dto.name;
    if (dto.slug !== undefined) updateValues.slug = dto.slug;
    if (dto.description !== undefined)
      updateValues.description = dto.description;
    if (dto.price !== undefined) updateValues.price = dto.price.toString();
    if (dto.stock !== undefined) updateValues.stock = dto.stock;
    if (dto.isActive !== undefined) updateValues.isActive = dto.isActive;

    if (categoryId) {
      const category = await this.drizzle.db
        .select({ id: categories.id })
        .from(categories)
        .where(eq(categories.id, categoryId))
        .limit(1);

      if (!category.length) {
        throw new NotFoundException(`Category with ID ${categoryId} not found`);
      }
      updateValues.categoryId = categoryId;
    }

    const [updatedProduct] = await this.drizzle.db
      .update(products)
      .set(updateValues)
      .where(eq(products.id, id))
      .returning();

    return this.findOne(updatedProduct.id);
  }

  async deleteImage(productId: string, imageId: string) {
    const [image] = await this.drizzle.db
      .select()
      .from(mediaAssets)
      .where(
        and(eq(mediaAssets.id, imageId), eq(mediaAssets.productId, productId)),
      )
      .limit(1);

    if (!image) throw new NotFoundException('Image not found');

    // ✅ Using Cloudflare
    await this.cloudflareService.deleteImage(image.publicId);
    await this.drizzle.db
      .delete(mediaAssets)
      .where(eq(mediaAssets.id, imageId));

    return { message: 'Image deleted successfully' };
  }

  async remove(id: string) {
    const product = await this.findOne(id);

    // 🚀 OPTIMIZATION 3: Delete from Cloudflare in parallel instead of sequentially
    if (product.images && product.images.length > 0) {
      await Promise.all(
        product.images.map((image) =>
          this.cloudflareService.deleteImage(image.publicId),
        ),
      );
    }

    const [deletedProduct] = await this.drizzle.db
      .delete(products)
      .where(eq(products.id, id))
      .returning();

    return deletedProduct;
  }

  // 🚀 OPTIMIZATION 4: Atomic stock update to prevent race conditions
  async updateVariantStock(variantId: string, quantity: number) {
    const [updatedVariant] = await this.drizzle.db
      .update(productVariants)
      .set({
        stock: sql`${productVariants.stock} - ${quantity}`,
        updatedAt: new Date(),
      })
      .where(
        and(
          eq(productVariants.id, variantId),
          sql`${productVariants.stock} >= ${quantity}`, // Ensure sufficient stock atomically
        ),
      )
      .returning();

    if (!updatedVariant) {
      const exists = await this.drizzle.db
        .select({ id: productVariants.id })
        .from(productVariants)
        .where(eq(productVariants.id, variantId))
        .limit(1);

      if (!exists.length) {
        throw new NotFoundException(`Variant with ID ${variantId} not found`);
      }
      throw new BadRequestException('Insufficient stock');
    }

    return updatedVariant;
  }

  private async findVariantWithRelations(variantId: string) {
    const variant = await this.drizzle.db.query.productVariants.findFirst({
      where: eq(productVariants.id, variantId),
      with: { product: true, color: true, size: true },
    });

    if (!variant)
      throw new NotFoundException(`Variant with ID ${variantId} not found`);
    return variant;
  }

  async getFeaturedProducts(limit: number = 10) {
    return this.drizzle.db.query.products.findMany({
      where: eq(products.isActive, true),
      orderBy: [desc(products.createdAt)],
      limit,
      with: {
        category: true,
        images: true,
        variants: { with: { color: true, size: true } },
      },
    });
  }

  async searchProducts(
    searchTerm: string,
    filters?: {
      categoryId?: string;
      minPrice?: number;
      maxPrice?: number;
      brand?: string;
      sortBy?: 'price_asc' | 'price_desc' | 'newest' | 'popular';
      page?: number;
      limit?: number;
    },
  ) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 20;
    const offset = (page - 1) * limit;

    const conditions: SQL[] = [eq(products.isActive, true)];

    if (searchTerm && searchTerm.trim()) {
      const searchPattern = `%${searchTerm.toLowerCase()}%`;
      // 🚀 OPTIMIZATION 5: Use native ILIKE instead of LOWER() + LIKE
      conditions.push(
        sql`(${products.name} ILIKE ${searchPattern} OR ${products.description} ILIKE ${searchPattern})`,
      );
    }

    if (filters?.categoryId)
      conditions.push(eq(products.categoryId, filters.categoryId));
    if (filters?.minPrice !== undefined)
      conditions.push(
        sql`CAST(${products.price} AS DECIMAL) >= ${filters.minPrice}`,
      );
    if (filters?.maxPrice !== undefined)
      conditions.push(
        sql`CAST(${products.price} AS DECIMAL) <= ${filters.maxPrice}`,
      );

    let orderExpression: SQL = desc(products.createdAt);
    if (filters?.sortBy) {
      switch (filters.sortBy) {
        case 'price_asc':
          orderExpression = sql`CAST(${products.price} AS DECIMAL) ASC`;
          break;
        case 'price_desc':
          orderExpression = sql`CAST(${products.price} AS DECIMAL) DESC`;
          break;
        case 'newest':
          orderExpression = desc(products.createdAt);
          break;
        case 'popular':
          orderExpression = desc(products.stock);
          break;
      }
    }

    const countResult = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(products)
      .where(and(...conditions));

    const total = Number(countResult[0]?.count) || 0;

    const productsWithRelations = await this.drizzle.db.query.products.findMany(
      {
        where: and(...conditions),
        orderBy: [orderExpression],
        limit,
        offset,
        with: {
          category: true,
          images: true,
          variants: { with: { color: true, size: true } },
        },
      },
    );

    return {
      products: productsWithRelations,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // 🚀 OPTIMIZATION 6: Use Postgres Recursive CTE instead of JS While Loop
  private async getAllDescendantCategoryIds(
    parentId: string,
  ): Promise<string[]> {
    const result = await this.drizzle.db.execute(sql`
      WITH RECURSIVE category_tree AS (
        SELECT id FROM categories WHERE id = ${parentId}
        UNION ALL
        SELECT c.id FROM categories c
        INNER JOIN category_tree ct ON c.parent_id = ct.id
      )
      SELECT id FROM category_tree WHERE id != ${parentId};
    `);

    // ✅ FIXED: Drizzle returns a pg QueryResult object. We must access the 'rows' array inside it.
    const rows = (result as unknown as { rows: Array<Record<string, unknown>> })
      .rows;

    return rows.map((row) => row.id as string);
  }

  async getProductsByCategory(
    categoryId: string,
    filters?: {
      minPrice?: number;
      maxPrice?: number;
      sortBy?: string;
      page?: number;
      limit?: number;
    },
  ) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 20;
    const offset = (page - 1) * limit;

    const category = await this.drizzle.db
      .select({ id: categories.id })
      .from(categories)
      .where(eq(categories.id, categoryId))
      .limit(1);

    if (!category.length) {
      throw new NotFoundException(`Category with ID ${categoryId} not found`);
    }

    const descendantCategoryIds =
      await this.getAllDescendantCategoryIds(categoryId);
    const categoryIds = [categoryId, ...descendantCategoryIds];

    const conditions: SQL[] = [
      eq(products.isActive, true),
      inArray(products.categoryId, categoryIds),
    ];

    if (filters?.minPrice !== undefined)
      conditions.push(
        sql`CAST(${products.price} AS DECIMAL) >= ${filters.minPrice}`,
      );
    if (filters?.maxPrice !== undefined)
      conditions.push(
        sql`CAST(${products.price} AS DECIMAL) <= ${filters.maxPrice}`,
      );

    let orderExpression: SQL = desc(products.createdAt);
    if (filters?.sortBy === 'price_asc')
      orderExpression = sql`CAST(${products.price} AS DECIMAL) ASC`;
    else if (filters?.sortBy === 'price_desc')
      orderExpression = sql`CAST(${products.price} AS DECIMAL) DESC`;

    const results = await this.drizzle.db.query.products.findMany({
      where: and(...conditions),
      orderBy: [orderExpression],
      limit,
      offset,
      with: {
        category: true,
        images: true,
        variants: { with: { color: true, size: true } },
      },
    });

    const countResult = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(products)
      .where(and(...conditions));

    const total = Number(countResult[0]?.count) || 0;

    return {
      products: results,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async debugCategory(categoryId: string) {
    const category = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, categoryId))
      .limit(1);

    const allDescendantIds = await this.getAllDescendantCategoryIds(categoryId);

    const directSubcategories = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.parentId, categoryId));

    const parentProducts = await this.drizzle.db
      .select()
      .from(products)
      .where(
        and(eq(products.categoryId, categoryId), eq(products.isActive, true)),
      );

    const allDescendantProducts =
      allDescendantIds.length > 0
        ? await this.drizzle.db
            .select()
            .from(products)
            .where(
              and(
                inArray(products.categoryId, allDescendantIds),
                eq(products.isActive, true),
              ),
            )
        : [];

    return {
      category: category[0] || null,
      directSubcategoriesCount: directSubcategories.length,
      allDescendantCategoriesCount: allDescendantIds.length,
      allDescendantCategoryIds: allDescendantIds,
      parentProductCount: parentProducts.length,
      descendantProductCount: allDescendantProducts.length,
      totalProducts: parentProducts.length + allDescendantProducts.length,
    };
  }

  async getProductFilters() {
    const priceRange = await this.drizzle.db
      .select({
        min: sql<number>`MIN(CAST(${products.price} AS DECIMAL))`,
        max: sql<number>`MAX(CAST(${products.price} AS DECIMAL))`,
      })
      .from(products)
      .where(eq(products.isActive, true));

    const categoriesWithCounts = await this.drizzle.db
      .select({
        id: categories.id,
        name: categories.name,
        slug: categories.slug,
        count: sql<number>`count(${products.id})`,
      })
      .from(categories)
      .leftJoin(products, eq(products.categoryId, categories.id))
      .where(eq(products.isActive, true))
      .groupBy(categories.id);

    return {
      priceRange: {
        min: Number(priceRange[0]?.min) || 0,
        max: Number(priceRange[0]?.max) || 10000,
      },
      categories: categoriesWithCounts,
    };
  }
}
