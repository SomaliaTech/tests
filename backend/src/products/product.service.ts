import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import {
  CreateProductDto,
  CreateProductVariantDto,
  UploadBase64ImageDto,
} from './dto/create-product.dto';

@Injectable()
export class ProductsService {
  constructor(
    private prisma: PrismaService,
    private cloudinaryService: CloudinaryService,
  ) {}

  async create(createProductDto: CreateProductDto) {
    const { categoryId, imageUrls, ...productData } = createProductDto;

    const category = await this.prisma.category.findUnique({
      where: { id: categoryId },
    });

    if (!category) {
      throw new NotFoundException(`Category with ID ${categoryId} not found`);
    }

    const product = await this.prisma.product.create({
      data: {
        ...productData,
        price: productData.price,
        stock: productData.stock,
        category: {
          connect: { id: categoryId },
        },
      },
      include: {
        category: true,
        images: true,
        variants: {
          include: {
            color: true,
            size: true,
          },
        },
      },
    });

    if (imageUrls && imageUrls.length > 0) {
      await this.uploadImagesFromUrls(product.id, imageUrls);
    }

    return this.findOne(product.id);
  }

  async uploadImagesFromUrls(productId: string, imageUrls: string[]) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    const uploadResults = await Promise.all(
      imageUrls.map((url) =>
        this.cloudinaryService.uploadFromUrl(url, 'products'),
      ),
    );

    const images = await Promise.all(
      uploadResults.map((result) =>
        this.prisma.mediaAsset.create({
          data: {
            url: result.secure_url,
            publicId: result.public_id,
            productId,
          },
        }),
      ),
    );

    return images;
  }

  async uploadBase64Image(productId: string, base64Dto: UploadBase64ImageDto) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    const result = await this.cloudinaryService.uploadBase64(
      base64Dto.base64Image,
      'products',
    );

    const image = await this.prisma.mediaAsset.create({
      data: {
        url: result.secure_url,
        publicId: result.public_id,
        productId,
      },
    });

    return image;
  }

  async addVariant(
    productId: string,
    createVariantDto: CreateProductVariantDto,
  ) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    const color = await this.prisma.color.findUnique({
      where: { id: createVariantDto.colorId },
    });

    const size = await this.prisma.size.findUnique({
      where: { id: createVariantDto.sizeId },
    });

    if (!color || !size) {
      throw new NotFoundException('Color or Size not found');
    }

    const existingVariant = await this.prisma.productVariant.findUnique({
      where: {
        productId_colorId_sizeId: {
          productId,
          colorId: createVariantDto.colorId,
          sizeId: createVariantDto.sizeId,
        },
      },
    });

    if (existingVariant) {
      throw new BadRequestException(
        'Variant with this color and size already exists',
      );
    }

    return this.prisma.productVariant.create({
      data: {
        productId,
        colorId: createVariantDto.colorId,
        sizeId: createVariantDto.sizeId,
        sku: createVariantDto.sku,
        stock: createVariantDto.stock,
        price: createVariantDto.price,
      },
      include: {
        color: true,
        size: true,
      },
    });
  }

  async findAll() {
    return this.prisma.product.findMany({
      where: { isActive: true },
      include: {
        category: true,
        images: true,
        variants: {
          include: {
            color: true,
            size: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOne(id: string) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: {
        category: true,
        images: true,
        variants: {
          include: {
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

  // async findBySlug(slug: string) {
  //   const product = await this.prisma.product.findFirst({
  //     where: {
  //       slug: slug,
  //       isActive: true,
  //     },
  //     include: {
  //       category: true,
  //       images: true,
  //       variants: {
  //         include: {
  //           color: true,
  //           size: true,
  //         },
  //       },
  //     },
  //   });

  //   if (!product) {
  //     throw new NotFoundException(`Product with slug ${slug} not found`);
  //   }

  //   return product;
  // }

  // async update(id: string, updateProductDto: UpdateProductDto) {
  //   await this.findOne(id);

  //   const { categoryId, ...updateData } = updateProductDto;

  //   const data: Prisma.ProductUpdateInput = { ...updateData };

  //   if (categoryId) {
  //     const category = await this.prisma.category.findUnique({
  //       where: { id: categoryId },
  //     });
  //     if (!category) {
  //       throw new NotFoundException(`Category with ID ${categoryId} not found`);
  //     }
  //     data.category = { connect: { id: categoryId } };
  //   }

  //   return this.prisma.product.update({
  //     where: { id },
  //     data,
  //     include: {
  //       category: true,
  //       images: true,
  //       variants: {
  //         include: {
  //           color: true,
  //           size: true,
  //         },
  //       },
  //     },
  //   });
  // }

  async deleteImage(productId: string, imageId: string) {
    const image = await this.prisma.mediaAsset.findFirst({
      where: { id: imageId, productId },
    });

    if (!image) {
      throw new NotFoundException('Image not found');
    }

    // await this.cloudinaryService.deleteImage(image.publicId);

    await this.prisma.mediaAsset.delete({
      where: { id: imageId },
    });

    return { message: 'Image deleted successfully' };
  }

  async remove(id: string) {
    const product = await this.findOne(id);

    if (product.images && product.images.length > 0) {
      // for (const image of product.images) {
      //   await this.cloudinaryService.deleteImage(image.publicId);
      // }
    }

    return this.prisma.product.delete({
      where: { id },
    });
  }

  async updateVariantStock(variantId: string, quantity: number) {
    const variant = await this.prisma.productVariant.findUnique({
      where: { id: variantId },
    });

    if (!variant) {
      throw new NotFoundException(`Variant with ID ${variantId} not found`);
    }

    const newStock = variant.stock - quantity;
    if (newStock < 0) {
      throw new BadRequestException('Insufficient stock');
    }

    return this.prisma.productVariant.update({
      where: { id: variantId },
      data: { stock: newStock },
    });
  }
}
