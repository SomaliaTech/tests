import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
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

@Injectable()
export class ProductsService {
  constructor(
    private drizzle: DrizzleService,
    private cloudinaryService: CloudinaryService,
  ) {}

  async create(createProductDto: CreateProductDto) {
    const { categoryId, imageUrls, ...productData } = createProductDto;

    const category = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, categoryId))
      .limit(1);

    if (!category.length) {
      throw new NotFoundException(`Category with ID ${categoryId} not found`);
    }

    let slug = productData.slug;
    if (!slug) {
      slug = productData.name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '');

      let isUnique = false;
      let counter = 1;
      let finalSlug = slug;

      while (!isUnique) {
        const existingProduct = await this.drizzle.db
          .select()
          .from(products)
          .where(eq(products.slug, finalSlug))
          .limit(1);

        if (existingProduct.length === 0) {
          isUnique = true;
        } else {
          finalSlug = `${slug}-${counter}`;
          counter++;
        }
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
      .select()
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);

    if (!product.length) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    const uploadResults = await Promise.all(
      imageUrls.map((url) =>
        this.cloudinaryService.uploadFromUrl(url, 'products'),
      ),
    );

    const images = await Promise.all(
      uploadResults.map((result) =>
        this.drizzle.db
          .insert(mediaAssets)
          .values({
            url: result.secure_url,
            publicId: result.public_id,
            productId,
          })
          .returning(),
      ),
    );

    return images.flat();
  }

  async uploadBase64Image(productId: string, base64Dto: UploadBase64ImageDto) {
    const product = await this.drizzle.db
      .select()
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);

    if (!product.length) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    const result = await this.cloudinaryService.uploadBase64(
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
    const product = await this.drizzle.db
      .select()
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);

    if (!product.length) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    const color = await this.drizzle.db
      .select()
      .from(colors)
      .where(eq(colors.id, createVariantDto.colorId))
      .limit(1);

    if (!color.length) {
      throw new NotFoundException(
        `Color with ID ${createVariantDto.colorId} not found`,
      );
    }

    const size = await this.drizzle.db
      .select()
      .from(sizes)
      .where(eq(sizes.id, createVariantDto.sizeId))
      .limit(1);

    if (!size.length) {
      throw new NotFoundException(
        `Size with ID ${createVariantDto.sizeId} not found`,
      );
    }

    const existingVariant = await this.drizzle.db
      .select()
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
    const results = await this.drizzle.db.query.products.findMany({
      where: eq(products.isActive, true),
      with: {
        category: true,
        images: true,
        variants: {
          with: {
            color: true,
            size: true,
          },
        },
      },
      orderBy: [desc(products.createdAt)],
    });

    return results;
  }

  async findOne(id: string) {
    const product = await this.drizzle.db.query.products.findFirst({
      where: eq(products.id, id),
      with: {
        category: true,
        images: true,
        variants: {
          with: {
            color: true,
            size: true,
          },
        },
      },
    });

    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }

    return product;
  }

  async findBySlug(slug: string) {
    const product = await this.drizzle.db.query.products.findFirst({
      where: and(eq(products.isActive, true), eq(products.slug, slug)),
      with: {
        category: true,
        images: true,
        variants: {
          with: {
            color: true,
            size: true,
          },
        },
      },
    });

    if (!product) {
      throw new NotFoundException(`Product with slug ${slug} not found`);
    }

    return product;
  }

  async update(id: string, updateProductDto: UpdateProductDto) {
    await this.findOne(id);

    const { categoryId, ...updateData } = updateProductDto;
    const updateValues: any = { updatedAt: new Date() };

    if (updateData.name !== undefined) updateValues.name = updateData.name;
    if (updateData.slug !== undefined) updateValues.slug = updateData.slug;
    if (updateData.description !== undefined)
      updateValues.description = updateData.description;
    if (updateData.price !== undefined)
      updateValues.price = updateData.price.toString();
    if (updateData.stock !== undefined) updateValues.stock = updateData.stock;
    if (updateData.isActive !== undefined)
      updateValues.isActive = updateData.isActive;

    if (categoryId) {
      const category = await this.drizzle.db
        .select()
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
    const image = await this.drizzle.db
      .select()
      .from(mediaAssets)
      .where(
        and(eq(mediaAssets.id, imageId), eq(mediaAssets.productId, productId)),
      )
      .limit(1);

    if (!image.length) {
      throw new NotFoundException('Image not found');
    }

    await this.cloudinaryService.deleteImage(image[0].publicId);

    await this.drizzle.db
      .delete(mediaAssets)
      .where(eq(mediaAssets.id, imageId));

    return { message: 'Image deleted successfully' };
  }

  async remove(id: string) {
    const product = await this.findOne(id);

    if (product.images && product.images.length > 0) {
      for (const image of product.images) {
        await this.cloudinaryService.deleteImage(image.publicId);
      }
    }

    const [deletedProduct] = await this.drizzle.db
      .delete(products)
      .where(eq(products.id, id))
      .returning();

    return deletedProduct;
  }

  async updateVariantStock(variantId: string, quantity: number) {
    const variant = await this.drizzle.db
      .select()
      .from(productVariants)
      .where(eq(productVariants.id, variantId))
      .limit(1);

    if (!variant.length) {
      throw new NotFoundException(`Variant with ID ${variantId} not found`);
    }

    const newStock = variant[0].stock - quantity;
    if (newStock < 0) {
      throw new BadRequestException('Insufficient stock');
    }

    const [updatedVariant] = await this.drizzle.db
      .update(productVariants)
      .set({
        stock: newStock,
        updatedAt: new Date(),
      })
      .where(eq(productVariants.id, variantId))
      .returning();

    return updatedVariant;
  }

  private async findVariantWithRelations(variantId: string) {
    const variant = await this.drizzle.db.query.productVariants.findFirst({
      where: eq(productVariants.id, variantId),
      with: {
        product: true,
        color: true,
        size: true,
      },
    });

    if (!variant) {
      throw new NotFoundException(`Variant with ID ${variantId} not found`);
    }

    return variant;
  }

  // ✅ COMPLETE FIX FOR SEARCH METHOD TYPE ERRORS
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

    // ✅ FIX: Explicitly specify 'any' to handle chain mutations safely
    let query: any = this.drizzle.db.select().from(products);

    // ✅ FIX: Explicitly type condition list as Drizzle SQL array
    const conditions: SQL[] = [];

    conditions.push(eq(products.isActive, true));

    if (searchTerm && searchTerm.trim()) {
      const searchPattern = `%${searchTerm.toLowerCase()}%`;
      conditions.push(
        sql`(LOWER(${products.name}) LIKE ${searchPattern} OR 
             LOWER(${products.description}) LIKE ${searchPattern})`,
      );
    }

    if (filters?.categoryId) {
      conditions.push(eq(products.categoryId, filters.categoryId));
    }

    if (filters?.minPrice !== undefined) {
      conditions.push(
        sql`CAST(${products.price} AS DECIMAL) >= ${filters.minPrice}`,
      );
    }

    if (filters?.maxPrice !== undefined) {
      conditions.push(
        sql`CAST(${products.price} AS DECIMAL) <= ${filters.maxPrice}`,
      );
    }

    if (conditions.length > 0) {
      query = query.where(and(...conditions));
    }

    if (filters?.sortBy) {
      switch (filters.sortBy) {
        case 'price_asc':
          query = query.orderBy(sql`CAST(${products.price} AS DECIMAL) ASC`);
          break;
        case 'price_desc':
          query = query.orderBy(sql`CAST(${products.price} AS DECIMAL) DESC`);
          break;
        case 'newest':
          query = query.orderBy(sql`${products.createdAt} DESC`);
          break;
        case 'popular':
          query = query.orderBy(sql`${products.stock} DESC`);
          break;
      }
    } else {
      query = query.orderBy(sql`${products.createdAt} DESC`);
    }

    const countResult = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(products)
      .where(and(...conditions));

    const total = Number(countResult[0]?.count) || 0;
    const results = await query.limit(limit).offset(offset);

    const productsWithRelations = await Promise.all(
      results.map(async (product: any) => {
        const images = await this.drizzle.db
          .select()
          .from(mediaAssets)
          .where(eq(mediaAssets.productId, product.id));

        const variants = await this.drizzle.db
          .select()
          .from(productVariants)
          .where(eq(productVariants.productId, product.id));

        const [category] = await this.drizzle.db
          .select()
          .from(categories)
          .where(eq(categories.id, product.categoryId));

        return {
          ...product,
          images,
          variants,
          category,
        };
      }),
    );

    return {
      products: productsWithRelations,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getFeaturedProducts(limit: number = 10) {
    return this.drizzle.db
      .select()
      .from(products)
      .where(eq(products.isActive, true))
      .orderBy(sql`${products.createdAt} DESC`)
      .limit(limit);
  }

  // ✅ COMPLETE FIX FOR GET CATEGORY METHOD TYPE ERRORS
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

    // Fetch subcategories
    const subcategories = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.parentId, categoryId));

    // Combine main category ID with all child subcategory IDs
    const categoryIds = [categoryId, ...subcategories.map((c) => c.id)];

    // Use explicit 'any' type to allow clean query-chaining mutations later
    let query: any = this.drizzle.db
      .select()
      .from(products)
      .where(
        and(
          eq(products.isActive, true),
          // ✅ FIX: Use native 'inArray' which is type-safe and built for array matching
          inArray(products.categoryId, categoryIds),
        ),
      );

    if (filters?.minPrice !== undefined) {
      query = query.where(
        sql`CAST(${products.price} AS DECIMAL) >= ${filters.minPrice}`,
      );
    }

    if (filters?.maxPrice !== undefined) {
      query = query.where(
        sql`CAST(${products.price} AS DECIMAL) <= ${filters.maxPrice}`,
      );
    }

    if (filters?.sortBy === 'price_asc') {
      query = query.orderBy(sql`CAST(${products.price} AS DECIMAL) ASC`);
    } else if (filters?.sortBy === 'price_desc') {
      query = query.orderBy(sql`CAST(${products.price} AS DECIMAL) DESC`);
    } else {
      query = query.orderBy(sql`${products.createdAt} DESC`);
    }

    const results = await query.limit(limit).offset(offset);

    // Get your total count for pagination calculations
    const countResult = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(products)
      .where(
        and(
          eq(products.isActive, true),
          // ✅ FIX: Match the type-safe inArray syntax here too
          inArray(products.categoryId, categoryIds),
        ),
      );

    const total = Number(countResult[0]?.count) || 0;

    return {
      products: results,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
  async getProductFilters() {
    // Get unique prices or categories
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
