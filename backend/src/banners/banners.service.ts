// src/banners/banners.service.ts
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { banners } from '../drizzle/schema';
import { eq, and, asc, desc, like, or, SQL, sql, inArray } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { CreateBannerDto } from './dto/create-banner.dto';
import { UpdateBannerDto } from './dto/update-banner.dto';
import { SupabaseService } from '../supabase/supabase.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class BannersService {
  private readonly logger = new Logger(BannersService.name);

  constructor(
    private drizzle: DrizzleService,
    private supabaseService: SupabaseService,
    @Inject(forwardRef(() => NotificationsService))
    private notificationsService: NotificationsService,
  ) {}

  // ==========================================
  // IMAGE UPLOAD
  // ==========================================

  async uploadImage(base64Image: string, fileName: string) {
    try {
      this.logger.log(`Uploading banner image: ${fileName}`);

      if (!base64Image || !base64Image.startsWith('data:image/')) {
        throw new BadRequestException(
          'Invalid image format. Expected base64 data URI.',
        );
      }

      const result = await this.supabaseService.uploadBase64(
        base64Image,
        'banners',
      );

      this.logger.log(`Banner image uploaded: ${result.secure_url}`);

      return {
        imageUrl: result.secure_url,
        publicId: result.public_id,
      };
    } catch (error) {
      this.logger.error(`Image upload failed: ${error}`);
      throw new BadRequestException(
        `Failed to upload image: ${error.message || error}`,
      );
    }
  }

  // ==========================================
  // PUBLIC METHODS
  // ==========================================

  async getActiveBanners() {
    this.logger.log('🔍 Fetching ALL banners (no filter)...');

    const result = await this.drizzle.db
      .select()
      .from(banners)
      .orderBy(asc(banners.order), desc(banners.createdAt));

    this.logger.log(`📊 Total banners in DB: ${result.length}`);
    this.logger.log(
      `📊 Active banners: ${result.filter((b) => b.isActive).length}`,
    );

    result.forEach((b) => {
      this.logger.log(
        `  - ${b.id}: title="${b.title}", isActive=${b.isActive}, hasDiscount=${b.hasDiscount}, isFlashSale=${b.isFlashSale}`,
      );
    });

    return result
      .filter((b) => b.isActive)
      .map((b) => this.formatBannerResponse(b));
  }

  async getActiveDiscountBanners() {
    const now = new Date();

    const result = await this.drizzle.db
      .select()
      .from(banners)
      .where(
        and(
          eq(banners.isActive, true),
          eq(banners.hasDiscount, true),
          sql`(
            (${banners.discountStartDate} IS NULL OR ${banners.discountStartDate} <= ${now}) AND
            (${banners.discountEndDate} IS NULL OR ${banners.discountEndDate} >= ${now})
          )`,
        ),
      )
      .orderBy(asc(banners.order), desc(banners.createdAt));

    return result.map((b) => this.formatBannerResponse(b));
  }

  async getActiveFlashSaleBanners() {
    const now = new Date();

    const result = await this.drizzle.db
      .select()
      .from(banners)
      .where(
        and(
          eq(banners.isActive, true),
          eq(banners.isFlashSale, true),
          sql`(
            (${banners.flashSaleStartTime} IS NULL OR ${banners.flashSaleStartTime} <= ${now}) AND
            (${banners.flashSaleEndTime} IS NULL OR ${banners.flashSaleEndTime} >= ${now})
          )`,
        ),
      )
      .orderBy(asc(banners.order), desc(banners.createdAt));

    return result.map((b) => this.formatBannerResponse(b));
  }

  // ==========================================
  // ADMIN METHODS - PAGINATED
  // ==========================================

  async getAllBanners(
    page: number = 1,
    limit: number = 20,
    search?: string,
    isActive?: boolean,
    hasDiscount?: boolean,
    isFlashSale?: boolean,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = [];

    if (search && search.trim()) {
      const pattern = `%${search.trim()}%`;
      conditions.push(
        or(
          like(banners.title, pattern),
          like(banners.subtitle, pattern),
          like(banners.discountCode, pattern),
        )!,
      );
    }

    if (isActive !== undefined) {
      conditions.push(eq(banners.isActive, isActive));
    }

    if (hasDiscount !== undefined) {
      conditions.push(eq(banners.hasDiscount, hasDiscount));
    }

    if (isFlashSale !== undefined) {
      conditions.push(eq(banners.isFlashSale, isFlashSale));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [items, total] = await Promise.all([
      this.drizzle.db
        .select()
        .from(banners)
        .where(whereClause)
        .orderBy(asc(banners.order), desc(banners.createdAt))
        .limit(limit)
        .offset(offset),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(banners)
        .where(whereClause),
    ]);

    return {
      items: items.map((b) => this.formatBannerResponse(b)),
      pagination: {
        page,
        limit,
        total: total[0]?.count || 0,
        totalPages: Math.ceil((total[0]?.count || 0) / limit),
      },
    };
  }

  async getBannerById(id: string) {
    const [banner] = await this.drizzle.db
      .select()
      .from(banners)
      .where(eq(banners.id, id))
      .limit(1);

    if (!banner) {
      throw new NotFoundException('Banner not found');
    }

    return this.formatBannerResponse(banner);
  }

  /**
   * ✅ Create banner (admin only)
   */
  async createBanner(createBannerDto: CreateBannerDto, userId: string) {
    this.validateColors(createBannerDto);

    if (!createBannerDto.imageUrl) {
      throw new BadRequestException('Image URL is required');
    }

    this.validateDiscountSettings(createBannerDto);
    this.validateFlashSaleSettings(createBannerDto);

    const [banner] = await this.drizzle.db
      .insert(banners)
      .values({
        title: createBannerDto.title,
        subtitle: createBannerDto.subtitle || null,
        imageUrl: createBannerDto.imageUrl,
        buttonText: createBannerDto.buttonText || null,
        actionLink: createBannerDto.actionLink || null,
        backgroundColor: createBannerDto.backgroundColor || null,
        gradientStart: createBannerDto.gradientStart || null,
        gradientEnd: createBannerDto.gradientEnd || null,
        isActive: createBannerDto.isActive ?? true,
        order: createBannerDto.order ?? 0,
        createdBy: userId,
        hasDiscount: createBannerDto.hasDiscount ?? false,
        discountPercentage: createBannerDto.discountPercentage
          ? String(createBannerDto.discountPercentage)
          : null,
        discountAmount: createBannerDto.discountAmount
          ? String(createBannerDto.discountAmount)
          : null,
        discountCode: createBannerDto.discountCode || null,
        discountStartDate: createBannerDto.discountStartDate
          ? new Date(createBannerDto.discountStartDate)
          : null,
        discountEndDate: createBannerDto.discountEndDate
          ? new Date(createBannerDto.discountEndDate)
          : null,
        isFlashSale: createBannerDto.isFlashSale ?? false,
        flashSaleStartTime: createBannerDto.flashSaleStartTime
          ? new Date(createBannerDto.flashSaleStartTime)
          : null,
        flashSaleEndTime: createBannerDto.flashSaleEndTime
          ? new Date(createBannerDto.flashSaleEndTime)
          : null,
        flashSaleQuantity: createBannerDto.flashSaleQuantity || null,
        flashSalePrice: createBannerDto.flashSalePrice
          ? String(createBannerDto.flashSalePrice)
          : null,
      } as any)
      .returning();

    this.logger.log(
      `Banner created: ${banner.id} ` +
        `(Discount: ${banner.hasDiscount}, Flash Sale: ${banner.isFlashSale})`,
    );

    // ✅ Trigger notification in background (non-blocking)
    if (banner.isActive) {
      this.notificationsService
        .notifyAllUsersOfNewBanner(banner)
        .catch((err) => {
          this.logger.error(
            `❌ Failed to send banner push notifications: ${err}`,
          );
        });
    }

    return this.formatBannerResponse(banner);
  }

  private formatBannerResponse(banner: any) {
    return {
      ...banner,
      discountPercentage:
        banner.discountPercentage != null
          ? parseFloat(banner.discountPercentage)
          : null,
      discountAmount:
        banner.discountAmount != null
          ? parseFloat(banner.discountAmount)
          : null,
      flashSalePrice:
        banner.flashSalePrice != null
          ? parseFloat(banner.flashSalePrice)
          : null,
    };
  }

  async updateBanner(id: string, updateBannerDto: UpdateBannerDto) {
    const existingBanner = await this.getBannerById(id);

    this.validateColors(updateBannerDto);
    this.validateDiscountSettings(updateBannerDto);
    this.validateFlashSaleSettings(updateBannerDto);

    const updateData: any = { updatedAt: new Date() };

    const fields = [
      'title',
      'subtitle',
      'imageUrl',
      'buttonText',
      'actionLink',
      'backgroundColor',
      'gradientStart',
      'gradientEnd',
      'isActive',
      'order',
    ];

    for (const field of fields) {
      if (updateBannerDto[field] !== undefined) {
        updateData[field] = updateBannerDto[field];
      }
    }

    if (updateBannerDto.hasDiscount !== undefined)
      updateData.hasDiscount = updateBannerDto.hasDiscount;
    if (updateBannerDto.discountPercentage !== undefined)
      updateData.discountPercentage =
        updateBannerDto.discountPercentage != null
          ? String(updateBannerDto.discountPercentage)
          : null;
    if (updateBannerDto.discountAmount !== undefined)
      updateData.discountAmount =
        updateBannerDto.discountAmount != null
          ? String(updateBannerDto.discountAmount)
          : null;
    if (updateBannerDto.discountCode !== undefined)
      updateData.discountCode = updateBannerDto.discountCode || null;
    if (updateBannerDto.discountStartDate !== undefined)
      updateData.discountStartDate = updateBannerDto.discountStartDate
        ? new Date(updateBannerDto.discountStartDate)
        : null;
    if (updateBannerDto.discountEndDate !== undefined)
      updateData.discountEndDate = updateBannerDto.discountEndDate
        ? new Date(updateBannerDto.discountEndDate)
        : null;
    if (updateBannerDto.isFlashSale !== undefined)
      updateData.isFlashSale = updateBannerDto.isFlashSale;
    if (updateBannerDto.flashSaleStartTime !== undefined)
      updateData.flashSaleStartTime = updateBannerDto.flashSaleStartTime
        ? new Date(updateBannerDto.flashSaleStartTime)
        : null;
    if (updateBannerDto.flashSaleEndTime !== undefined)
      updateData.flashSaleEndTime = updateBannerDto.flashSaleEndTime
        ? new Date(updateBannerDto.flashSaleEndTime)
        : null;
    if (updateBannerDto.flashSaleQuantity !== undefined)
      updateData.flashSaleQuantity = updateBannerDto.flashSaleQuantity || null;
    if (updateBannerDto.flashSalePrice !== undefined)
      updateData.flashSalePrice =
        updateBannerDto.flashSalePrice != null
          ? String(updateBannerDto.flashSalePrice)
          : null;

    if (
      updateBannerDto.imageUrl &&
      updateBannerDto.imageUrl !== existingBanner.imageUrl &&
      existingBanner.imageUrl &&
      existingBanner.imageUrl.includes('supabase.co')
    ) {
      try {
        const oldPublicId = this.extractPublicId(existingBanner.imageUrl);
        if (oldPublicId) {
          await this.supabaseService.deleteImage(oldPublicId);
          this.logger.log(`Deleted old banner image: ${oldPublicId}`);
        }
      } catch (e) {
        this.logger.warn(`Failed to delete old banner image: ${e}`);
      }
    }

    const [updatedBanner] = await this.drizzle.db
      .update(banners)
      .set(updateData)
      .where(eq(banners.id, id))
      .returning();

    this.logger.log(
      `Banner updated: ${updatedBanner.id} ` +
        `(Discount: ${updatedBanner.hasDiscount}, Flash Sale: ${updatedBanner.isFlashSale})`,
    );
    return this.formatBannerResponse(updatedBanner);
  }

  async deleteBanner(id: string) {
    const banner = await this.getBannerById(id);

    if (banner.imageUrl && banner.imageUrl.includes('supabase.co')) {
      try {
        const publicId = this.extractPublicId(banner.imageUrl);
        if (publicId) {
          await this.supabaseService.deleteImage(publicId);
          this.logger.log(`Deleted banner image: ${publicId}`);
        }
      } catch (e) {
        this.logger.warn(`Failed to delete banner image: ${e}`);
      }
    }

    await this.drizzle.db.delete(banners).where(eq(banners.id, id));
    this.logger.log(`Banner deleted: ${id}`);
    return { message: 'Banner deleted successfully' };
  }

  async toggleBannerStatus(id: string) {
    const banner = await this.getBannerById(id);

    const [updatedBanner] = await this.drizzle.db
      .update(banners)
      .set({ isActive: !banner.isActive, updatedAt: new Date() })
      .where(eq(banners.id, id))
      .returning();

    this.logger.log(
      `Banner ${id} ${updatedBanner.isActive ? 'activated' : 'deactivated'}`,
    );
    return this.formatBannerResponse(updatedBanner);
  }

  async reorderBanners(bannerIds: string[]) {
    const existingBanners = await this.drizzle.db
      .select({ id: banners.id })
      .from(banners)
      .where(inArray(banners.id, bannerIds));

    if (existingBanners.length !== bannerIds.length) {
      throw new BadRequestException('One or more banner IDs are invalid');
    }

    for (let i = 0; i < bannerIds.length; i++) {
      await this.drizzle.db
        .update(banners)
        .set({ order: i, updatedAt: new Date() })
        .where(eq(banners.id, bannerIds[i]));
    }

    this.logger.log('Banners reordered');
    return { message: 'Banners reordered successfully' };
  }

  // ==========================================
  // VALIDATION HELPERS
  // ==========================================

  private validateColors(dto: any): void {
    const colorFields = ['backgroundColor', 'gradientStart', 'gradientEnd'];
    for (const field of colorFields) {
      const color = dto[field];
      if (color !== undefined && color !== null) {
        if (!this.isValidHexColor(color)) {
          throw new BadRequestException(
            `Invalid ${field} format. Expected hex color (e.g., #FF0000 or #F00)`,
          );
        }
      }
    }
  }

  private validateDiscountSettings(dto: any): void {
    if (dto.hasDiscount) {
      if (!dto.discountPercentage && !dto.discountAmount) {
        throw new BadRequestException(
          'Discount requires either percentage or amount',
        );
      }
      if (dto.discountPercentage && dto.discountAmount) {
        throw new BadRequestException(
          'Cannot have both discount percentage and amount',
        );
      }
      if (
        dto.discountPercentage &&
        (dto.discountPercentage < 0 || dto.discountPercentage > 100)
      ) {
        throw new BadRequestException(
          'Discount percentage must be between 0 and 100',
        );
      }
      if (dto.discountStartDate && dto.discountEndDate) {
        if (new Date(dto.discountEndDate) <= new Date(dto.discountStartDate)) {
          throw new BadRequestException(
            'Discount end date must be after start date',
          );
        }
      }
    }
  }

  private validateFlashSaleSettings(dto: any): void {
    if (dto.isFlashSale) {
      if (!dto.flashSaleStartTime || !dto.flashSaleEndTime) {
        throw new BadRequestException(
          'Flash sale requires both start and end times',
        );
      }
      if (new Date(dto.flashSaleEndTime) <= new Date(dto.flashSaleStartTime)) {
        throw new BadRequestException(
          'Flash sale end time must be after start time',
        );
      }
      if (!dto.flashSalePrice) {
        throw new BadRequestException('Flash sale requires a price');
      }
      if (dto.flashSalePrice <= 0) {
        throw new BadRequestException('Flash sale price must be positive');
      }
      if (
        dto.flashSaleQuantity !== undefined &&
        dto.flashSaleQuantity !== null &&
        dto.flashSaleQuantity < 1
      ) {
        throw new BadRequestException('Flash sale quantity must be at least 1');
      }
    }
  }

  private isValidHexColor(color: string): boolean {
    const hexRegex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/;
    return hexRegex.test(color);
  }

  private extractPublicId(url: string): string | null {
    try {
      const patterns = [
        /\/storage\/v1\/object\/public\/(.+)$/,
        /\/storage\/v1\/object\/public\/([^?]+)/,
        /banners\/([^?]+)$/,
      ];
      for (const pattern of patterns) {
        const match = url.match(pattern);
        if (match) return match[1];
      }
      return null;
    } catch {
      return null;
    }
  }
}
