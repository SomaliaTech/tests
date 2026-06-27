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
  cartItems,
} from '../drizzle/schema';
import { eq, and, desc, sql, SQL } from 'drizzle-orm';
import { SupabaseService } from 'src/supabase/supabase.service';
import { v4 as uuidv4 } from 'uuid';
import { AddToCartDto } from './dto/cart.dto';

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
    private supabaseService: SupabaseService,
  ) {}

  async create(createProductDto: CreateProductDto) {
    const { categoryId, imageUrls, variants, ...productData } =
      createProductDto;

    const category = await this.drizzle.db
      .select({ id: categories.id })
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

    // ✅ Convert decimal fields to strings
    const insertData: any = {
      ...productData,
      slug,
      price: productData.price.toString(),
      categoryId,
      isActive: productData.isActive ?? true,
    };

    // ✅ Convert optional decimal fields to strings
    if (productData.compareAtPrice !== undefined) {
      insertData.compareAtPrice = productData.compareAtPrice.toString();
    }
    if (productData.costPerItem !== undefined) {
      insertData.costPerItem = productData.costPerItem.toString();
    }
    if (productData.weight !== undefined) {
      insertData.weight = productData.weight.toString();
    }

    const [product] = await this.drizzle.db
      .insert(products)
      .values(insertData)
      .returning();

    if (imageUrls && imageUrls.length > 0) {
      await this.uploadImagesFromUrls(product.id, imageUrls);
    }

    // ✅ Handle variants if provided
    if (variants && variants.length > 0) {
      for (const variant of variants) {
        const variantData: any = {
          id: uuidv4(),
          productId: product.id,
          colorId: variant.colorId,
          sizeId: variant.sizeId,
          stock: variant.stock ?? 0,
        };

        // ✅ Convert optional fields
        if (variant.sku) variantData.sku = variant.sku;
        if (variant.price !== undefined) {
          variantData.price = variant.price.toString();
        }

        await this.drizzle.db.insert(productVariants).values(variantData);
      }
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

    const uploadResults = await Promise.all(
      imageUrls.map((url) =>
        this.supabaseService.uploadFromUrl(url, 'products'),
      ),
    );

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

    const result = await this.supabaseService.uploadBase64(
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
    console.log('🔍 [Products] Adding variant to product:', productId);
    console.log('📥 [Products] Variant DTO received:', createVariantDto);

    const [product] = await this.drizzle.db
      .select({ id: products.id })
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);

    if (!product) {
      console.error('❌ [Products] Product not found:', productId);
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    const [color] = await this.drizzle.db
      .select({ id: colors.id })
      .from(colors)
      .where(eq(colors.id, createVariantDto.colorId))
      .limit(1);

    if (!color) {
      console.error('❌ [Products] Color not found:', createVariantDto.colorId);
      throw new NotFoundException(
        `Color with ID ${createVariantDto.colorId} not found`,
      );
    }

    const [size] = await this.drizzle.db
      .select({ id: sizes.id })
      .from(sizes)
      .where(eq(sizes.id, createVariantDto.sizeId))
      .limit(1);

    if (!size) {
      console.error('❌ [Products] Size not found:', createVariantDto.sizeId);
      throw new NotFoundException(
        `Size with ID ${createVariantDto.sizeId} not found`,
      );
    }

    // Check for duplicate variant
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
      console.error('❌ [Products] Duplicate variant detected');
      throw new BadRequestException(
        'Variant with this color and size already exists',
      );
    }

    // Generate SKU if not provided
    const sku =
      createVariantDto.sku ||
      `${product.id.slice(0, 8)}-${color.id.slice(0, 4)}-${size.id.slice(0, 4)}`.toUpperCase();

    console.log('✅ [Products] All validations passed, inserting variant');
    console.log('✅ [Products] Generated SKU:', sku);

    // Insert variant with optional fields
    const [variant] = await this.drizzle.db
      .insert(productVariants)
      .values({
        id: uuidv4(),
        productId,
        colorId: createVariantDto.colorId,
        sizeId: createVariantDto.sizeId,
        sku: sku,
        stock: createVariantDto.stock ?? 0,
        price: createVariantDto.price?.toString() ?? null,
      })
      .returning();

    console.log('✅ [Products] Variant created successfully:', variant.id);

    return this.findVariantWithRelations(variant.id);
  }
  // ==========================================
  // CART METHODS
  // ==========================================

  async addToCart(userId: string, dto: AddToCartDto) {
    const { productId, productVariantId, quantity } = dto;

    let price: number;
    let stock: number;
    let productName: string;
    let actualVariantId: string | null = null;
    let colorName: string | null = null;
    let sizeName: string | null = null;

    if (productVariantId) {
      // ✅ User selected a specific variant (color + size)
      const variant = await this.drizzle.db.query.productVariants.findFirst({
        where: eq(productVariants.id, productVariantId),
        with: {
          product: { with: { images: true } },
          color: true,
          size: true,
        },
      });

      if (!variant) throw new NotFoundException('Product variant not found');
      if (variant.stock < quantity)
        throw new BadRequestException('Insufficient stock');

      price = variant.price
        ? Number(variant.price)
        : Number(variant.product?.price || 0);
      stock = variant.stock;
      productName = variant.product?.name || 'Product';
      actualVariantId = variant.id;
      colorName = variant.color?.name || null;
      sizeName = variant.size?.name || null;
    } else {
      // ✅ User is buying the base product (no variant)
      const product = await this.drizzle.db.query.products.findFirst({
        where: eq(products.id, productId),
        with: { images: true },
      });

      if (!product) throw new NotFoundException('Product not found');
      if (product.stock < quantity)
        throw new BadRequestException('Insufficient stock');

      price = Number(product.price);
      stock = product.stock;
      productName = product.name;
    }

    // Check if item already exists in cart
    const [existingItem] = await this.drizzle.db
      .select()
      .from(cartItems)
      .where(
        and(
          eq(cartItems.userId, userId),
          eq(cartItems.productId, productId),
          productVariantId
            ? eq(cartItems.productVariantId, productVariantId)
            : sql`${cartItems.productVariantId} IS NULL`,
        ),
      )
      .limit(1);

    let cartItemId: string;

    if (existingItem) {
      const newQuantity = existingItem.quantity + quantity;
      if (stock < newQuantity)
        throw new BadRequestException(
          'Insufficient stock for updated quantity',
        );

      const [updated] = await this.drizzle.db
        .update(cartItems)
        .set({ quantity: newQuantity, updatedAt: new Date() })
        .where(eq(cartItems.id, existingItem.id))
        .returning();
      cartItemId = updated.id;
    } else {
      const [newItem] = await this.drizzle.db
        .insert(cartItems)
        .values({
          id: uuidv4(),
          userId,
          productId,
          productVariantId: actualVariantId, // ✅ null if no variant
          quantity,
          createdAt: new Date(),
          updatedAt: new Date(),
        })
        .returning();
      cartItemId = newItem.id;
    }

    // Return formatted cart item
    const imageUrl = productVariantId
      ? (
          await this.drizzle.db.query.productVariants.findFirst({
            where: eq(productVariants.id, productVariantId),
            with: { product: { with: { images: true } } },
          })
        )?.product?.images?.[0]?.url || ''
      : (
          await this.drizzle.db.query.products.findFirst({
            where: eq(products.id, productId),
            with: { images: true },
          })
        )?.images?.[0]?.url || '';

    return {
      id: cartItemId,
      productVariantId: actualVariantId,
      productId: productId,
      name: productName,
      price: price,
      quantity: quantity,
      totalPrice: price * quantity,
      inStock: stock > 0,
      maxStock: stock,
      imageUrl: imageUrl,
      color: colorName,
      size: sizeName,
    };
  }
  async updateCartItem(userId: string, itemId: string, quantity: number) {
    if (quantity <= 0) {
      return this.removeCartItem(userId, itemId);
    }

    const [existingItem] = await this.drizzle.db
      .select()
      .from(cartItems)
      .where(and(eq(cartItems.id, itemId), eq(cartItems.userId, userId)))
      .limit(1);

    if (!existingItem) {
      throw new NotFoundException('Cart item not found');
    }

    // Check stock for both variant and non-variant cases
    if (existingItem.productVariantId) {
      const variant = await this.drizzle.db.query.productVariants.findFirst({
        where: eq(productVariants.id, existingItem.productVariantId),
      });

      if (variant && variant.stock < quantity) {
        throw new BadRequestException('Insufficient stock');
      }
    } else {
      const product = await this.drizzle.db.query.products.findFirst({
        where: eq(products.id, existingItem.productId as string),
      });

      if (product && product.stock < quantity) {
        throw new BadRequestException('Insufficient stock');
      }
    }

    const [updated] = await this.drizzle.db
      .update(cartItems)
      .set({ quantity, updatedAt: new Date() })
      .where(and(eq(cartItems.id, itemId), eq(cartItems.userId, userId)))
      .returning();

    if (!updated) {
      throw new NotFoundException('Cart item not found');
    }

    // ✅ FIXED: Load product with images
    const product = await this.drizzle.db.query.products.findFirst({
      where: eq(products.id, existingItem.productId as string),
      with: {
        images: true, // ✅ Added this to load images
      },
    });

    // Get variant details if it exists
    let variant: any = null;
    if (updated.productVariantId) {
      variant = await this.drizzle.db.query.productVariants.findFirst({
        where: eq(productVariants.id, updated.productVariantId),
        with: {
          color: true,
          size: true,
        },
      });
    }

    // If variant exists, use its price; otherwise use product price
    let unitPrice: number;
    if (variant && variant.price) {
      unitPrice = Number(variant.price);
    } else if (product) {
      unitPrice = Number(product.price);
    } else {
      unitPrice = 0;
    }

    // Get stock from variant or product
    let stock: number;
    if (variant) {
      stock = variant.stock;
    } else if (product) {
      stock = product.stock;
    } else {
      stock = 0;
    }

    return {
      id: updated.id,
      productVariantId: updated.productVariantId,
      productId: existingItem.productId as string,
      name: product?.name || 'Unknown Product',
      price: unitPrice,
      quantity: updated.quantity,
      totalPrice: unitPrice * updated.quantity,
      inStock: stock > 0,
      imageUrl: product?.images?.[0]?.url || '', // ✅ Now works
      color: variant?.color?.name || null,
      size: variant?.size?.name || null,
    };
  }

  async removeCartItem(userId: string, itemId: string) {
    const [deleted] = await this.drizzle.db
      .delete(cartItems)
      .where(and(eq(cartItems.id, itemId), eq(cartItems.userId, userId)))
      .returning();

    if (!deleted) {
      throw new NotFoundException('Cart item not found');
    }

    return { message: 'Cart item removed successfully' };
  }
  async getCartItems(userId: string) {
    const userCartItems = await this.drizzle.db.query.cartItems.findMany({
      where: eq(cartItems.userId, userId),
      with: {
        product: { with: { images: true } }, // ✅ Always load product
        variant: {
          with: {
            product: { with: { images: true } },
            color: true,
            size: true,
          },
        },
      },
    });

    return userCartItems.map((cartItem) => {
      // If variant exists, use variant data; otherwise use product data
      if (cartItem.variant) {
        const variant = cartItem.variant;
        const unitPrice = variant.price
          ? Number(variant.price)
          : Number(variant.product?.price || 0);

        return {
          id: cartItem.id,
          productVariantId: cartItem.productVariantId,
          productId: variant.product?.id || cartItem.productId || '',
          name: variant.product?.name || 'Unknown Product',
          price: unitPrice,
          quantity: cartItem.quantity,
          totalPrice: unitPrice * cartItem.quantity,
          inStock: variant.stock > 0,
          maxStock: variant.stock,
          imageUrl: variant.product?.images?.[0]?.url || '',
          color: variant.color?.name || null,
          size: variant.size?.name || null,
          hasVariant: true,
        };
      } else {
        // ✅ No variant - use product directly
        const product = cartItem.product;
        const unitPrice = product ? Number(product.price) : 0;

        return {
          id: cartItem.id,
          productVariantId: null,
          productId: cartItem.productId || '',
          name: product?.name || 'Unknown Product',
          price: unitPrice,
          quantity: cartItem.quantity,
          totalPrice: unitPrice * cartItem.quantity,
          inStock: (product?.stock || 0) > 0,
          maxStock: product?.stock || 0,
          imageUrl: product?.images?.[0]?.url || '',
          color: null,
          size: null,
          hasVariant: false,
        };
      }
    });
  }
  async clearCart(userId: string) {
    await this.drizzle.db.delete(cartItems).where(eq(cartItems.userId, userId));
    return { message: 'Cart cleared successfully' };
  }

  // ==========================================
  // PRODUCT METHODS
  // ==========================================

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

    const dto = updateProductDto as unknown as ProductUpdateShape;
    const categoryId = dto.categoryId;

    const updateValues: Record<string, any> = { updatedAt: new Date() };

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

    await this.supabaseService.deleteImage(image.publicId);
    await this.drizzle.db
      .delete(mediaAssets)
      .where(eq(mediaAssets.id, imageId));

    return { message: 'Image deleted successfully' };
  }

  async remove(id: string) {
    const product = await this.findOne(id);

    if (product.images && product.images.length > 0) {
      await Promise.all(
        product.images.map((image) =>
          this.supabaseService.deleteImage(image.publicId),
        ),
      );
    }

    const [deletedProduct] = await this.drizzle.db
      .delete(products)
      .where(eq(products.id, id))
      .returning();

    return deletedProduct;
  }

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
          sql`${productVariants.stock} >= ${quantity}`,
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
