import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
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
import { eq, and, desc } from 'drizzle-orm';

@Injectable()
export class ProductsService {
  constructor(
    private drizzle: DrizzleService,
    private cloudinaryService: CloudinaryService,
  ) {}

  async create(createProductDto: CreateProductDto) {
    const { categoryId, imageUrls, ...productData } = createProductDto;

    // Check if category exists
    const category = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, categoryId))
      .limit(1);

    if (!category.length) {
      throw new NotFoundException(`Category with ID ${categoryId} not found`);
    }

    // Generate slug if not provided
    let slug = productData.slug;
    if (!slug) {
      slug = productData.name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '');

      // Make sure slug is unique
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

    // Create product
    const [product] = await this.drizzle.db
      .insert(products)
      .values({
        ...productData,
        slug, // Use generated slug
        price: productData.price.toString(),
        categoryId,
        isActive: productData.isActive ?? true,
      })
      .returning();

    // Upload images if provided
    if (imageUrls && imageUrls.length > 0) {
      await this.uploadImagesFromUrls(product.id, imageUrls);
    }

    return this.findOne(product.id);
  }

  async uploadImagesFromUrls(productId: string, imageUrls: string[]) {
    // Check if product exists
    const product = await this.drizzle.db
      .select()
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);

    if (!product.length) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    // Upload to Cloudinary and save to database
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
    // Check if product exists
    const product = await this.drizzle.db
      .select()
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);

    if (!product.length) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    // Upload to Cloudinary
    const result = await this.cloudinaryService.uploadBase64(
      base64Dto.base64Image,
      'products',
    );

    // Save to database
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
    // Check if product exists
    const product = await this.drizzle.db
      .select()
      .from(products)
      .where(eq(products.id, productId))
      .limit(1);

    if (!product.length) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    // Check if color exists
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

    // Check if size exists
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

    // Check if variant already exists
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

    // Create variant - convert price to string if provided
    const [variant] = await this.drizzle.db
      .insert(productVariants)
      .values({
        productId,
        colorId: createVariantDto.colorId,
        sizeId: createVariantDto.sizeId,
        sku: createVariantDto.sku,
        stock: createVariantDto.stock,
        price: createVariantDto.price?.toString(), // Convert to string if exists
      })
      .returning();

    // Fetch the variant with relations
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
    // Check if product exists
    await this.findOne(id);

    const { categoryId, ...updateData } = updateProductDto;

    // Prepare update data
    const updateValues: any = {
      updatedAt: new Date(),
    };

    // Add fields that are present
    if (updateData.name !== undefined) updateValues.name = updateData.name;
    if (updateData.slug !== undefined) updateValues.slug = updateData.slug;
    if (updateData.description !== undefined)
      updateValues.description = updateData.description;
    if (updateData.price !== undefined)
      updateValues.price = updateData.price.toString();
    if (updateData.stock !== undefined) updateValues.stock = updateData.stock;
    if (updateData.isActive !== undefined)
      updateValues.isActive = updateData.isActive;

    // Update category if provided
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

    // Update product
    const [updatedProduct] = await this.drizzle.db
      .update(products)
      .set(updateValues)
      .where(eq(products.id, id))
      .returning();

    return this.findOne(updatedProduct.id);
  }

  async deleteImage(productId: string, imageId: string) {
    // Check if image exists and belongs to product
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

    // Delete from Cloudinary
    await this.cloudinaryService.deleteImage(image[0].publicId);

    // Delete from database
    await this.drizzle.db
      .delete(mediaAssets)
      .where(eq(mediaAssets.id, imageId));

    return { message: 'Image deleted successfully' };
  }

  async remove(id: string) {
    const product = await this.findOne(id);

    // Delete all associated images from Cloudinary
    if (product.images && product.images.length > 0) {
      for (const image of product.images) {
        await this.cloudinaryService.deleteImage(image.publicId);
      }
    }

    // Delete product (variants will be deleted due to CASCADE)
    const [deletedProduct] = await this.drizzle.db
      .delete(products)
      .where(eq(products.id, id))
      .returning();

    return deletedProduct;
  }

  async updateVariantStock(variantId: string, quantity: number) {
    // Check if variant exists
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

    // Update stock
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

  // Helper method to fetch variant with relations
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
}
