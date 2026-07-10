import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
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
  reviews,
} from '../drizzle/schema';
import { eq, and, desc, sql, SQL } from 'drizzle-orm';
import { SupabaseService } from 'src/supabase/supabase.service';
import { v4 as uuidv4 } from 'uuid';
import { AddToCartDto } from './dto/cart.dto';
import DataLoader from 'dataloader';

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
  private readonly logger = new Logger(ProductsService.name);

  // ✅ DataLoaders for batch loading
  private categoryLoader: DataLoader<string, any>;
  private imagesLoader: DataLoader<string, any[]>;
  private variantsLoader: DataLoader<string, any[]>;

  constructor(
    private drizzle: DrizzleService,
    private cloudflareService: CloudflareService,
    private supabaseService: SupabaseService,
  ) {
    // ✅ Initialize DataLoaders
    this.categoryLoader = new DataLoader(
      async (categoryIds: readonly string[]) => {
        const uniqueIds = [...new Set(categoryIds)].filter(Boolean);
        if (uniqueIds.length === 0) return [];

        const results = await this.drizzle.db
          .select()
          .from(categories)
          .where(inArray(categories.id, uniqueIds));

        const categoryMap = new Map();
        results.forEach((category) => {
          categoryMap.set(category.id, category);
        });

        return categoryIds.map((id) => categoryMap.get(id) || null);
      },
    );

    this.imagesLoader = new DataLoader(
      async (productIds: readonly string[]) => {
        const uniqueIds = [...new Set(productIds)].filter(Boolean);
        if (uniqueIds.length === 0) return [];

        const results = await this.drizzle.db
          .select()
          .from(mediaAssets)
          .where(inArray(mediaAssets.productId, uniqueIds))
          .orderBy(desc(mediaAssets.isMain), desc(mediaAssets.order));

        const imageMap = new Map<string, any[]>();
        results.forEach((image) => {
          // ✅ FIX: Handle null productId
          const productId = image.productId;
          if (productId) {
            if (!imageMap.has(productId)) {
              imageMap.set(productId, []);
            }
            imageMap.get(productId)!.push(image);
          }
        });

        return productIds.map((id) => imageMap.get(id) || []);
      },
    );

    this.variantsLoader = new DataLoader(
      async (productIds: readonly string[]) => {
        const uniqueIds = [...new Set(productIds)].filter(Boolean);
        if (uniqueIds.length === 0) return [];

        // ✅ FIX: Remove duplicate property names
        const results = await this.drizzle.db
          .select({
            id: productVariants.id,
            productId: productVariants.productId,
            colorId: productVariants.colorId,
            sizeId: productVariants.sizeId,
            sku: productVariants.sku,
            stock: productVariants.stock,
            price: productVariants.price,
            createdAt: productVariants.createdAt,
            updatedAt: productVariants.updatedAt,
            // ✅ Color fields (renamed to avoid conflicts)
            colorName: colors.name,
            colorCode: colors.code,
            // ✅ Size fields (renamed to avoid conflicts)
            sizeName: sizes.name,
            sizeValue: sizes.value,
          })
          .from(productVariants)
          .leftJoin(colors, eq(productVariants.colorId, colors.id))
          .leftJoin(sizes, eq(productVariants.sizeId, sizes.id))
          .where(inArray(productVariants.productId, uniqueIds));

        const variantMap = new Map<string, any[]>();
        results.forEach((variant) => {
          const productId = variant.productId;
          if (productId) {
            if (!variantMap.has(productId)) {
              variantMap.set(productId, []);
            }
            const variantWithRelations = {
              ...variant,
              color:
                variant.colorId && variant.colorName
                  ? {
                      id: variant.colorId,
                      name: variant.colorName,
                      code: variant.colorCode,
                    }
                  : null,
              size:
                variant.sizeId && variant.sizeName
                  ? {
                      id: variant.sizeId,
                      name: variant.sizeName,
                      value: variant.sizeValue,
                    }
                  : null,
            };
            variantMap.get(productId)!.push(variantWithRelations);
          }
        });

        return productIds.map((id) => variantMap.get(id) || []);
      },
    );
  }

  // ==========================================
  // PRODUCT CREATION
  // ==========================================

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

    const slug = await this._generateUniqueSlug(
      productData.slug,
      productData.name,
    );

    const insertData: any = {
      ...productData,
      slug,
      price: productData.price.toString(),
      categoryId,
      isActive: productData.isActive ?? true,
    };

    ['compareAtPrice', 'costPerItem', 'weight'].forEach((field) => {
      if (productData[field] !== undefined) {
        insertData[field] = productData[field].toString();
      }
    });

    const [product] = await this.drizzle.db
      .insert(products)
      .values(insertData)
      .returning();

    this.logger.log(`Product created: ${product.id} (${product.name})`);

    if (imageUrls && imageUrls.length > 0) {
      await this.uploadImagesFromUrls(product.id, imageUrls);
    }

    if (!variants || variants.length === 0) {
      await this._createBaseVariant(product, productData);
    } else {
      await this._createVariants(product.id, variants);
    }

    return this.findOne(product.id);
  }

  // ==========================================
  // IMAGE UPLOAD
  // ==========================================

  async uploadImagesFromUrls(productId: string, imageUrls: string[]) {
    await this._validateProductExists(productId);

    if (imageUrls.length > 10) {
      throw new BadRequestException('Maximum 10 images allowed');
    }

    const uploadResults = await Promise.all(
      imageUrls.map((url) =>
        this.supabaseService.uploadFromUrl(url, 'products'),
      ),
    );

    const imagesToInsert = uploadResults.map((result, index) => ({
      url: result.secure_url,
      publicId: result.public_id,
      productId,
      isMain: index === 0,
      order: index,
    }));

    const insertedImages = await this.drizzle.db
      .insert(mediaAssets)
      .values(imagesToInsert)
      .returning();

    this.logger.log(
      `Uploaded ${insertedImages.length} images for product ${productId}`,
    );
    return insertedImages;
  }

  async uploadBase64Image(productId: string, base64Dto: UploadBase64ImageDto) {
    await this._validateProductExists(productId);

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

    this.logger.log(`Uploaded base64 image for product ${productId}`);
    return image;
  }

  // ==========================================
  // VARIANT MANAGEMENT
  // ==========================================

  async addVariant(
    productId: string,
    createVariantDto: CreateProductVariantDto,
  ) {
    this.logger.log(`Adding variant to product: ${productId}`);

    await this._validateProductExists(productId);

    let color: { id: string } | null = null;
    if (createVariantDto.colorId) {
      [color] = await this.drizzle.db
        .select({ id: colors.id })
        .from(colors)
        .where(eq(colors.id, createVariantDto.colorId))
        .limit(1);

      if (!color) {
        throw new NotFoundException(
          `Color with ID ${createVariantDto.colorId} not found`,
        );
      }
    }

    let size: { id: string } | null = null;
    if (createVariantDto.sizeId) {
      [size] = await this.drizzle.db
        .select({ id: sizes.id })
        .from(sizes)
        .where(eq(sizes.id, createVariantDto.sizeId))
        .limit(1);

      if (!size) {
        throw new NotFoundException(
          `Size with ID ${createVariantDto.sizeId} not found`,
        );
      }
    }

    if (createVariantDto.colorId && createVariantDto.sizeId) {
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
    }

    const sku =
      createVariantDto.sku ||
      `${productId.slice(0, 8)}-${color?.id.slice(0, 4) || 'NO'}-${size?.id.slice(0, 4) || 'NO'}`.toUpperCase();

    const [variant] = await this.drizzle.db
      .insert(productVariants)
      .values({
        id: uuidv4(),
        productId,
        colorId: createVariantDto.colorId || null,
        sizeId: createVariantDto.sizeId || null,
        sku,
        stock: createVariantDto.stock ?? 0,
        price: createVariantDto.price?.toString() ?? null,
      })
      .returning();

    this.logger.log(`Variant created: ${variant.id} (SKU: ${sku})`);
    return this._findVariantWithRelations(variant.id);
  }

  async updateVariantStock(variantId: string, quantity: number) {
    if (quantity < 0) {
      throw new BadRequestException('Quantity cannot be negative');
    }

    const [updatedVariant] = await this.drizzle.db
      .update(productVariants)
      .set({
        stock: quantity,
        updatedAt: new Date(),
      })
      .where(eq(productVariants.id, variantId))
      .returning();

    if (!updatedVariant) {
      throw new NotFoundException(`Variant with ID ${variantId} not found`);
    }

    this.logger.log(`Variant ${variantId} stock updated to ${quantity}`);
    return updatedVariant;
  }

  // ==========================================
  // CART METHODS
  // ==========================================

  async addToCart(userId: string, dto: AddToCartDto) {
    const { productId, productVariantId, quantity } = dto;

    if (quantity < 1) {
      throw new BadRequestException('Quantity must be at least 1');
    }

    let price: number;
    let stock: number;
    let productName: string;
    let actualVariantId: string | null = null;
    let colorName: string | null = null;
    let sizeName: string | null = null;
    let imageUrl: string = '';

    if (productVariantId) {
      const variant = await this.drizzle.db.query.productVariants.findFirst({
        where: eq(productVariants.id, productVariantId),
        with: {
          product: { with: { images: true } },
          color: true,
          size: true,
        },
      });

      if (!variant) {
        throw new NotFoundException('Product variant not found');
      }

      if (variant.stock < quantity) {
        throw new BadRequestException('Insufficient stock');
      }

      price = variant.price
        ? Number(variant.price)
        : Number(variant.product?.price || 0);
      stock = variant.stock;
      productName = variant.product?.name || 'Product';
      actualVariantId = variant.id;
      colorName = variant.color?.name || null;
      sizeName = variant.size?.name || null;
      imageUrl = variant.product?.images?.[0]?.url || '';
    } else {
      const product = await this.drizzle.db.query.products.findFirst({
        where: eq(products.id, productId),
        with: { images: true },
      });

      if (!product) {
        throw new NotFoundException('Product not found');
      }

      if (product.stock < quantity) {
        throw new BadRequestException('Insufficient stock');
      }

      price = Number(product.price);
      stock = product.stock;
      productName = product.name;
      imageUrl = product.images?.[0]?.url || '';
    }

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
      if (stock < newQuantity) {
        throw new BadRequestException(
          'Insufficient stock for updated quantity',
        );
      }

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
          productVariantId: actualVariantId,
          quantity,
        })
        .returning();
      cartItemId = newItem.id;
    }

    return {
      id: cartItemId,
      productVariantId: actualVariantId,
      productId,
      name: productName,
      price,
      quantity,
      totalPrice: price * quantity,
      inStock: stock > 0,
      maxStock: stock,
      imageUrl,
      color: colorName,
      size: sizeName,
    };
  }

  async updateCartItem(userId: string, itemId: string, quantity: number) {
    if (quantity < 0) {
      throw new BadRequestException('Quantity cannot be negative');
    }

    if (quantity === 0) {
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

    const product = await this.drizzle.db.query.products.findFirst({
      where: eq(products.id, existingItem.productId as string),
      with: { images: true },
    });

    let variant: any = null;
    if (updated.productVariantId) {
      variant = await this.drizzle.db.query.productVariants.findFirst({
        where: eq(productVariants.id, updated.productVariantId),
        with: { color: true, size: true },
      });
    }

    const unitPrice = variant?.price
      ? Number(variant.price)
      : product
        ? Number(product.price)
        : 0;
    const stock = variant?.stock ?? product?.stock ?? 0;

    return {
      id: updated.id,
      productVariantId: updated.productVariantId,
      productId: existingItem.productId as string,
      name: product?.name || 'Unknown Product',
      price: unitPrice,
      quantity: updated.quantity,
      totalPrice: unitPrice * updated.quantity,
      inStock: stock > 0,
      imageUrl: product?.images?.[0]?.url || '',
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
        product: { with: { images: true } },
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
      }

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
    });
  }

  async clearCart(userId: string) {
    await this.drizzle.db.delete(cartItems).where(eq(cartItems.userId, userId));
    return { message: 'Cart cleared successfully' };
  }

  // ==========================================
  // PRODUCT QUERIES (WITH REVIEW STATS & DATALOADER)
  // ==========================================
  // GET ALL PRODUCTS
  // ==========================================

  // ==========================================
  // GET PRODUCTS BY CATEGORY
  // ==========================================

  async findOne(id: string) {
    const product = await this.drizzle.db.query.products.findFirst({
      where: eq(products.id, id),
      with: {
        category: true,
        images: {
          orderBy: [desc(mediaAssets.isMain), desc(mediaAssets.order)],
        },
        variants: {
          with: { color: true, size: true },
          limit: 10,
        },
      },
      extras: this._reviewStatsExtras,
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
        images: {
          orderBy: [desc(mediaAssets.isMain), desc(mediaAssets.order)],
        },
        variants: {
          with: { color: true, size: true },
          limit: 10,
        },
      },
      extras: this._reviewStatsExtras,
    });

    if (!product) {
      throw new NotFoundException(`Product with slug ${slug} not found`);
    }
    return product;
  }

  async getFeaturedProducts(limit: number = 6) {
    const orderExpressions = this._getOrderExpression('newest');

    const productsList = await this.drizzle.db.query.products.findMany({
      where: and(eq(products.isActive, true), eq(products.isFeatured, true)),
      orderBy: orderExpressions as any,
      limit: Math.min(limit, 20),
      with: {
        category: true,
        images: {
          orderBy: [desc(mediaAssets.isMain), desc(mediaAssets.order)],
        },
      },
      extras: this._reviewStatsExtras,
    });

    const productIds = productsList.map((p) => p.id);
    if (productIds.length > 0) {
      const variantsMap = await this.variantsLoader.loadMany(productIds);

      return productsList.map((product, index) => ({
        ...product,
        variants: Array.isArray(variantsMap[index]) ? variantsMap[index] : [],
      }));
    }

    return productsList;
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
      .groupBy(categories.id)
      .orderBy(desc(sql<number>`count(${products.id})`));

    return {
      priceRange: {
        min: Number(priceRange[0]?.min) || 0,
        max: Number(priceRange[0]?.max) || 10000,
      },
      categories: categoriesWithCounts,
    };
  }

  // ==========================================
  // PRODUCT UPDATE & DELETE
  // ==========================================

  async update(id: string, updateProductDto: UpdateProductDto) {
    await this.findOne(id);

    const updateValues: Record<string, any> = { updatedAt: new Date() };

    const fields = ['name', 'slug', 'description', 'stock', 'isActive'];
    for (const field of fields) {
      if (updateProductDto[field] !== undefined) {
        updateValues[field] = updateProductDto[field];
      }
    }

    if (updateProductDto.price !== undefined) {
      updateValues.price = updateProductDto.price.toString();
    }

    if (updateProductDto.categoryId) {
      const category = await this.drizzle.db
        .select({ id: categories.id })
        .from(categories)
        .where(eq(categories.id, updateProductDto.categoryId))
        .limit(1);

      if (!category.length) {
        throw new NotFoundException(
          `Category with ID ${updateProductDto.categoryId} not found`,
        );
      }
      updateValues.categoryId = updateProductDto.categoryId;
    }

    const [updatedProduct] = await this.drizzle.db
      .update(products)
      .set(updateValues)
      .where(eq(products.id, id))
      .returning();

    this.logger.log(`Product updated: ${id}`);
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

    if (!image) {
      throw new NotFoundException('Image not found');
    }

    await this.supabaseService.deleteImage(image.publicId);
    await this.drizzle.db
      .delete(mediaAssets)
      .where(eq(mediaAssets.id, imageId));

    this.logger.log(`Image deleted: ${imageId}`);
    return { message: 'Image deleted successfully' };
  }

  async remove(id: string) {
    const product = await this.findOne(id);

    if (product.images && product.images.length > 0) {
      await Promise.all(
        product.images.map((image) =>
          this.supabaseService.deleteImage(image.publicId).catch((e) => {
            this.logger.warn(`Failed to delete image ${image.publicId}: ${e}`);
          }),
        ),
      );
    }

    const [deletedProduct] = await this.drizzle.db
      .delete(products)
      .where(eq(products.id, id))
      .returning();

    this.logger.log(`Product deleted: ${id}`);
    return deletedProduct;
  }

  // ==========================================
  // DEBUG & HELPERS
  // ==========================================

  async debugCategory(categoryId: string) {
    const category = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, categoryId))
      .limit(1);

    const allDescendantIds =
      await this._getAllDescendantCategoryIds(categoryId);

    const [directSubcategories, parentProducts, allDescendantProducts] =
      await Promise.all([
        this.drizzle.db
          .select()
          .from(categories)
          .where(eq(categories.parentId, categoryId)),
        this.drizzle.db
          .select()
          .from(products)
          .where(
            and(
              eq(products.categoryId, categoryId),
              eq(products.isActive, true),
            ),
          ),
        allDescendantIds.length > 0
          ? this.drizzle.db
              .select()
              .from(products)
              .where(
                and(
                  inArray(products.categoryId, allDescendantIds),
                  eq(products.isActive, true),
                ),
              )
          : [],
      ]);

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

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  private async _validateProductExists(productId: string): Promise<void> {
    const [product] = await this.drizzle.db
      .select({ id: products.id })
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);

    if (!product) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }
  }

  private async _generateUniqueSlug(
    providedSlug?: string,
    name?: string,
  ): Promise<string> {
    const baseSlug =
      providedSlug ||
      name
        ?.toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '') ||
      'product';

    const existingSlugs = await this.drizzle.db
      .select({ slug: products.slug })
      .from(products)
      .where(sql`${products.slug} LIKE ${baseSlug + '%'}`);

    const slugSet = new Set(existingSlugs.map((s) => s.slug));

    if (!slugSet.has(baseSlug)) {
      return baseSlug;
    }

    let counter = 1;
    while (slugSet.has(`${baseSlug}-${counter}`)) {
      counter++;
    }
    return `${baseSlug}-${counter}`;
  }

  private async _createBaseVariant(
    product: any,
    productData: any,
  ): Promise<void> {
    const baseSku = `${product.id.slice(0, 8)}-BASE`.toUpperCase();

    await this.drizzle.db.insert(productVariants).values({
      id: uuidv4(),
      productId: product.id,
      colorId: null,
      sizeId: null,
      sku: baseSku,
      stock: productData.stock ?? 0,
      price: productData.price.toString(),
    });

    this.logger.log(
      `Base variant created for product ${product.id}: ${baseSku}`,
    );
  }

  private async _createVariants(
    productId: string,
    variants: any[],
  ): Promise<void> {
    for (const variant of variants) {
      const variantData: any = {
        id: uuidv4(),
        productId,
        colorId: variant.colorId || null,
        sizeId: variant.sizeId || null,
        stock: variant.stock ?? 0,
      };

      if (variant.sku) variantData.sku = variant.sku;
      if (variant.price !== undefined) {
        variantData.price = variant.price.toString();
      }

      await this.drizzle.db.insert(productVariants).values(variantData);
    }
    this.logger.log(
      `Created ${variants.length} variants for product ${productId}`,
    );
  }

  private async _findVariantWithRelations(variantId: string) {
    const variant = await this.drizzle.db.query.productVariants.findFirst({
      where: eq(productVariants.id, variantId),
      with: { product: true, color: true, size: true },
    });

    if (!variant) {
      throw new NotFoundException(`Variant with ID ${variantId} not found`);
    }
    return variant;
  }

  private async _getAllDescendantCategoryIds(
    parentId: string,
  ): Promise<string[]> {
    const result = await this.drizzle.db.execute(sql`
      WITH RECURSIVE category_tree AS (
        SELECT id FROM categories WHERE id = ${parentId}
        UNION ALL
        SELECT c.id FROM categories c
        INNER JOIN category_tree ct ON c.parent_id = ct.id
        WHERE c.is_active = true
      )
      SELECT id FROM category_tree WHERE id != ${parentId};
    `);

    const rows = (result as unknown as { rows: Array<Record<string, unknown>> })
      .rows;

    return rows.map((row) => row.id as string);
  }

  private _getOrderExpression(sortBy?: string): SQL[] {
    switch (sortBy) {
      case 'price_asc':
        return [sql`CAST(${products.price} AS DECIMAL) ASC`, desc(products.id)];
      case 'price_desc':
        return [
          sql`CAST(${products.price} AS DECIMAL) DESC`,
          desc(products.id),
        ];
      case 'discount_desc':
        return [
          sql`CAST(COALESCE(${products.compareAtPrice}, ${products.price}) AS DECIMAL) - CAST(${products.price} AS DECIMAL) DESC`,
          desc(products.id),
        ];
      case 'newest':
        return [desc(products.createdAt), desc(products.id)];
      case 'popular':
        return [desc(products.stock), desc(products.id)];
      default:
        return [desc(products.createdAt), desc(products.id)];
    }
  }
  private get _reviewStatsExtras() {
    return {
      // ✅ CRITICAL FIX: Use raw SQL strings for the 'reviews' table.
      // Using ${reviews.rating} inside 'extras' causes Drizzle to incorrectly map it to "products"."rating".
      rating:
        sql<number>`COALESCE(ROUND((SELECT AVG(r.rating)::numeric FROM reviews r WHERE r.product_id = ${products.id}), 1), 0)`.as(
          'rating',
        ),
      reviewCount:
        sql<number>`COALESCE((SELECT COUNT(*)::int FROM reviews r WHERE r.product_id = ${products.id}), 0)`.as(
          'reviewCount',
        ),
    };
  }

  // ✅ NEW HELPER: Batch fetch review stats in ONE query instead of N queries
  private async _batchFetchReviewStats(productIds: string[]) {
    const reviewStatsMap = new Map<
      string,
      { rating: number; reviewCount: number }
    >();
    if (productIds.length === 0) return reviewStatsMap;

    const stats = await this.drizzle.db
      .select({
        productId: reviews.productId,
        avgRating: sql<string>`COALESCE(ROUND(AVG(${reviews.rating}::numeric), 1), '0')`,
        reviewCount: sql<string>`COUNT(*)`,
      })
      .from(reviews)
      .where(inArray(reviews.productId, productIds))
      .groupBy(reviews.productId);

    stats.forEach((s) => {
      reviewStatsMap.set(s.productId, {
        rating: Number(s.avgRating),
        reviewCount: Number(s.reviewCount),
      });
    });

    return reviewStatsMap;
  }

  // ==========================================
  // ✅ UPDATED: FIND ALL
  // ==========================================
  async findAll(filters?: {
    sortBy?: string;
    limit?: number;
    page?: number;
    minPrice?: number;
    maxPrice?: number;
    categoryId?: string;
  }) {
    const limit = Math.min(filters?.limit || 20, 50);
    const page = Math.max(filters?.page || 1, 1);
    const offset = (page - 1) * limit;

    const conditions: SQL[] = [eq(products.isActive, true)];
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

    const orderExpressions = this._getOrderExpression(filters?.sortBy);

    const [countResult, productsList] = await Promise.all([
      this.drizzle.db
        .select({ count: sql<number>`count(*)` })
        .from(products)
        .where(and(...conditions)),
      this.drizzle.db.query.products.findMany({
        where: and(...conditions),
        orderBy: orderExpressions as any,
        limit,
        offset,
        with: {
          category: true,
          images: {
            orderBy: [desc(mediaAssets.isMain), desc(mediaAssets.order)],
          },
          variants: { with: { color: true, size: true } },
        },
        // ❌ REMOVED: extras: this._reviewStatsExtras
      }),
    ]);

    // ✅ INDUSTRY SOLUTION: Batch fetch review stats
    const productIds = productsList.map((p) => p.id);
    const reviewStatsMap = await this._batchFetchReviewStats(productIds);

    const total = Number(countResult[0]?.count) || 0;
    const productsWithRelations = productsList.map((product) => {
      const stats = reviewStatsMap.get(product.id) || {
        rating: 0,
        reviewCount: 0,
      };
      return {
        ...product,
        rating: stats.rating,
        reviewCount: stats.reviewCount,
        images: (product.images || []).sort((a: any, b: any) => {
          if (a.isMain && !b.isMain) return -1;
          if (!a.isMain && b.isMain) return 1;
          return (a.order || 0) - (b.order || 0);
        }),
      };
    });

    return {
      products: productsWithRelations,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ==========================================
  // ✅ UPDATED: GET PRODUCTS BY CATEGORY
  // ==========================================
  async getProductsByCategory(categoryId: string, filters?: any) {
    const page = Math.max(filters?.page || 1, 1);
    const limit = Math.min(filters?.limit || 20, 50);
    const offset = (page - 1) * limit;

    const category = await this.drizzle.db
      .select({ id: categories.id })
      .from(categories)
      .where(eq(categories.id, categoryId))
      .limit(1);
    if (!category.length)
      throw new NotFoundException(`Category with ID ${categoryId} not found`);

    const descendantCategoryIds =
      await this._getAllDescendantCategoryIds(categoryId);
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

    const orderExpressions = this._getOrderExpression(filters?.sortBy);

    const [countResult, productsList] = await Promise.all([
      this.drizzle.db
        .select({ count: sql<number>`count(*)` })
        .from(products)
        .where(and(...conditions)),
      this.drizzle.db.query.products.findMany({
        where: and(...conditions),
        orderBy: orderExpressions as any,
        limit,
        offset,
        with: {
          category: true,
          images: {
            orderBy: [desc(mediaAssets.isMain), desc(mediaAssets.order)],
          },
          variants: { with: { color: true, size: true } },
        },
        // ❌ REMOVED: extras: this._reviewStatsExtras
      }),
    ]);

    const productIds = productsList.map((p) => p.id);
    const reviewStatsMap = await this._batchFetchReviewStats(productIds);

    const total = Number(countResult[0]?.count) || 0;
    const productsWithRelations = productsList.map((product) => {
      const stats = reviewStatsMap.get(product.id) || {
        rating: 0,
        reviewCount: 0,
      };
      return {
        ...product,
        rating: stats.rating,
        reviewCount: stats.reviewCount,
      };
    });

    return {
      products: productsWithRelations,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ==========================================
  // ✅ UPDATED: SEARCH PRODUCTS
  // ==========================================
  async searchProducts(searchTerm: string, filters?: any) {
    const page = Math.max(filters?.page || 1, 1);
    const limit = Math.min(filters?.limit || 20, 50);
    const offset = (page - 1) * limit;

    const conditions: SQL[] = [eq(products.isActive, true)];
    if (searchTerm && searchTerm.trim()) {
      const searchPattern = `%${searchTerm.toLowerCase().trim()}%`;
      conditions.push(
        sql`(${products.name} ILIKE ${searchPattern} OR ${products.description} ILIKE ${searchPattern} OR ${products.brand} ILIKE ${searchPattern})`,
      );
    }
    if (filters?.categoryId)
      conditions.push(eq(products.categoryId, filters.categoryId));
    if (filters?.brand)
      conditions.push(sql`${products.brand} ILIKE ${`%${filters.brand}%`}`);
    if (filters?.minPrice !== undefined)
      conditions.push(
        sql`CAST(${products.price} AS DECIMAL) >= ${filters.minPrice}`,
      );
    if (filters?.maxPrice !== undefined)
      conditions.push(
        sql`CAST(${products.price} AS DECIMAL) <= ${filters.maxPrice}`,
      );

    const orderExpressions = this._getOrderExpression(filters?.sortBy);

    const [countResult, productsList] = await Promise.all([
      this.drizzle.db
        .select({ count: sql<number>`count(*)` })
        .from(products)
        .where(and(...conditions)),
      this.drizzle.db.query.products.findMany({
        where: and(...conditions),
        orderBy: orderExpressions as any,
        limit,
        offset,
        with: {
          category: true,
          images: {
            orderBy: [desc(mediaAssets.isMain), desc(mediaAssets.order)],
          },
          variants: { with: { color: true, size: true }, limit: 10 },
        },
        // ❌ REMOVED: extras: this._reviewStatsExtras
      }),
    ]);

    const productIds = productsList.map((p) => p.id);
    const reviewStatsMap = await this._batchFetchReviewStats(productIds);

    const total = Number(countResult[0]?.count) || 0;
    const productsWithRelations = productsList.map((product) => {
      const stats = reviewStatsMap.get(product.id) || {
        rating: 0,
        reviewCount: 0,
      };
      return {
        ...product,
        rating: stats.rating,
        reviewCount: stats.reviewCount,
      };
    });

    return {
      products: productsWithRelations,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}
