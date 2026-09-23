import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
  ConflictException,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import {
  affiliateRequests,
  affiliates,
  promoCodes,
  promoCodeUsage,
  affiliateCommissions,
  users,
  orders,
  notifications,
  affiliateSettings,
} from '../drizzle/schema';
import {
  eq,
  and,
  desc,
  sql,
  or,
  like,
  gte,
  lte,
  inArray,
  count,
  SQL,
} from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/notification.entity';
import { ChatGateway } from '../chat/chat.gateway';
import {
  ApplyAffiliateDto,
  CreatePromoCodeDto,
  ReviewAffiliateRequestDto,
  RejectAffiliateRequestDto,
  UpdateAffiliateDto,
  UpdatePromoCodeDto,
  PayCommissionDto,
} from './dto/affiliate.dto';
import { WaafiPayService } from 'src/payment/waafipay.service';
import { UpdateAffiliateSettingsDto } from './dto/affiliate-settings.dto';

@Injectable()
export class AffiliateService {
  private readonly logger = new Logger(AffiliateService.name);

  constructor(
    private drizzle: DrizzleService,
    private notificationsService: NotificationsService,
    private waafiPayService: WaafiPayService,
    private chatGateway: ChatGateway,
  ) {}

  async getAffiliateSettings() {
    const rows = await this.drizzle.db
      .select()
      .from(affiliateSettings)
      .limit(1);

    if (rows.length === 0) {
      // Seed with defaults
      const [created] = await this.drizzle.db
        .insert(affiliateSettings)
        .values({})
        .returning();
      return this._serializeSettings(created);
    }

    return this._serializeSettings(rows[0]);
  }

  async updateAffiliateSettings(dto: UpdateAffiliateSettingsDto) {
    const updateData: Record<string, unknown> = {
      updatedAt: new Date(),
    };

    if (dto.defaultCommissionRate !== undefined)
      updateData.defaultCommissionRate = dto.defaultCommissionRate.toString();
    if (dto.minPayoutAmount !== undefined)
      updateData.minPayoutAmount = dto.minPayoutAmount.toString();
    if (dto.payoutCycleDays !== undefined)
      updateData.payoutCycleDays = dto.payoutCycleDays;

    if (dto.defaultDiscountType !== undefined)
      updateData.defaultDiscountType = dto.defaultDiscountType;
    if (dto.defaultDiscountValue !== undefined)
      updateData.defaultDiscountValue = dto.defaultDiscountValue.toString();
    if (dto.defaultMaxUsesPerUser !== undefined)
      updateData.defaultMaxUsesPerUser = dto.defaultMaxUsesPerUser;

    if (dto.requireApproval !== undefined)
      updateData.requireApproval = dto.requireApproval;
    if (dto.autoApprovePromoCodes !== undefined)
      updateData.autoApprovePromoCodes = dto.autoApprovePromoCodes;
    if (dto.allowSelfReferral !== undefined)
      updateData.allowSelfReferral = dto.allowSelfReferral;
    if (dto.cookieWindowDays !== undefined)
      updateData.cookieWindowDays = dto.cookieWindowDays;

    if (dto.notifyOnNewApplication !== undefined)
      updateData.notifyOnNewApplication = dto.notifyOnNewApplication;
    if (dto.notifyOnNewCommission !== undefined)
      updateData.notifyOnNewCommission = dto.notifyOnNewCommission;
    if (dto.notifyOnCodeApproval !== undefined)
      updateData.notifyOnCodeApproval = dto.notifyOnCodeApproval;
    if (dto.emailDigest !== undefined) updateData.emailDigest = dto.emailDigest;

    // Does a row exist?
    const rows = await this.drizzle.db
      .select({ id: affiliateSettings.id })
      .from(affiliateSettings)
      .limit(1);

    let updated;

    if (rows.length === 0) {
      const [created] = await this.drizzle.db
        .insert(affiliateSettings)
        .values(updateData as any)
        .returning();
      updated = created;
    } else {
      const [result] = await this.drizzle.db
        .update(affiliateSettings)
        .set(updateData)
        .where(eq(affiliateSettings.id, rows[0].id))
        .returning();
      updated = result;
    }

    return {
      message: 'Settings updated successfully',
      settings: this._serializeSettings(updated),
    };
  }
  // ==========================================
  // USER: Apply for Affiliate Status
  // ==========================================
  async applyForAffiliate(userId: string, dto: ApplyAffiliateDto) {
    // Check if user already has an affiliate account
    const existingAffiliate = await this.drizzle.db
      .select()
      .from(affiliates)
      .where(eq(affiliates.userId, userId))
      .limit(1);

    if (existingAffiliate.length > 0) {
      throw new BadRequestException(
        'You are already an approved affiliate marketer',
      );
    }

    // Check for pending request
    const pendingRequest = await this.drizzle.db
      .select()
      .from(affiliateRequests)
      .where(
        and(
          eq(affiliateRequests.userId, userId),
          eq(affiliateRequests.status, 'PENDING'),
        ),
      )
      .limit(1);

    if (pendingRequest.length > 0) {
      throw new BadRequestException(
        'You already have a pending affiliate request. Please wait for review.',
      );
    }

    const [request] = await this.drizzle.db
      .insert(affiliateRequests)
      .values({
        id: uuidv4(),
        userId,
        businessName: dto.businessName,
        description: dto.description || null,
        phoneNumber: dto.phoneNumber || null,
        socialMediaLinks: dto.socialMediaLinks || null,
        expectedAudience: dto.expectedAudience || null,
        status: 'PENDING',
      })
      .returning();

    // Notify all super admins
    this.notifySuperAdmins('affiliate_request', {
      title: '🎯 New Affiliate Application',
      message: `${request.businessName} has applied to become an affiliate marketer`,
      actionLink: `/admin/affiliate/requests`,
    });

    // Notify the user
    await this.notificationsService.create({
      userId,
      type: NotificationType.SYSTEM,
      title: '📋 Affiliate Application Submitted',
      message: `Your application for "${dto.businessName}" has been submitted. We'll review it shortly.`,
      actionText: 'View Status',
      actionLink: '/affiliate/status',
    });

    return {
      message: 'Affiliate application submitted successfully',
      request,
    };
  }

  // ==========================================
  // USER: Get My Affiliate Status
  // ==========================================
  async getMyStatus(userId: string) {
    // Check approved affiliate
    const affiliate = await this.drizzle.db.query.affiliates.findFirst({
      where: eq(affiliates.userId, userId),
      with: {
        user: {
          columns: { id: true, name: true, phoneNumber: true, email: true },
        },
      },
    });

    if (affiliate) {
      // Get promo codes count
      const promoCodeCount = await this.drizzle.db
        .select({ count: count() })
        .from(promoCodes)
        .where(eq(promoCodes.affiliateId, affiliate.id));

      // Get recent commissions
      const recentCommissions = await this.drizzle.db
        .select()
        .from(affiliateCommissions)
        .where(eq(affiliateCommissions.affiliateId, affiliate.id))
        .orderBy(desc(affiliateCommissions.createdAt))
        .limit(5);

      return {
        status: 'APPROVED',
        isAffiliate: true,
        affiliate: {
          ...affiliate,
          totalEarnings: Number(affiliate.totalEarnings),
          paidEarnings: Number(affiliate.paidEarnings),
          pendingEarnings: Number(affiliate.pendingEarnings),
          commissionRate: Number(affiliate.commissionRate),
        },
        promoCodesCount: promoCodeCount[0]?.count || 0,
        recentCommissions,
      };
    }

    // Check pending request
    const pendingRequest = await this.drizzle.db
      .select()
      .from(affiliateRequests)
      .where(eq(affiliateRequests.userId, userId))
      .orderBy(desc(affiliateRequests.createdAt))
      .limit(1);

    if (pendingRequest.length > 0) {
      return {
        status: pendingRequest[0].status,
        isAffiliate: false,
        request: pendingRequest[0],
      };
    }

    return {
      status: 'NONE',
      isAffiliate: false,
      request: null,
    };
  }

  // ==========================================
  // USER: Get My Affiliate Stats
  // ==========================================
  async getMyStats(userId: string) {
    const affiliate = await this.drizzle.db.query.affiliates.findFirst({
      where: and(
        eq(affiliates.userId, userId),
        eq(affiliates.status, 'ACTIVE'),
      ),
    });

    if (!affiliate) {
      throw new ForbiddenException('You are not an active affiliate');
    }

    // Get all promo codes with usage stats
    const myPromoCodes = await this.drizzle.db
      .select({
        id: promoCodes.id,
        code: promoCodes.code,
        description: promoCodes.description,
        discountType: promoCodes.discountType,
        discountValue: promoCodes.discountValue,
        usedCount: promoCodes.usedCount,
        maxUses: promoCodes.maxUses,
        isActive: promoCodes.isActive,
        expiresAt: promoCodes.expiresAt,
        totalRevenue: sql<string>`COALESCE(SUM(CAST(${promoCodeUsage.orderAmount} AS DECIMAL)), 0)`,
        totalDiscountGiven: sql<string>`COALESCE(SUM(CAST(${promoCodeUsage.discountAmount} AS DECIMAL)), 0)`,
        totalCustomers: sql<number>`COUNT(DISTINCT ${promoCodeUsage.userId})::int`,
      })
      .from(promoCodes)
      .leftJoin(promoCodeUsage, eq(promoCodeUsage.promoCodeId, promoCodes.id))
      .where(eq(promoCodes.affiliateId, affiliate.id))
      .groupBy(promoCodes.id)
      .orderBy(desc(promoCodes.createdAt));

    // Get commission breakdown
    const commissionStats = await this.drizzle.db
      .select({
        status: affiliateCommissions.status,
        count: count(),
        total: sql<string>`COALESCE(SUM(CAST(${affiliateCommissions.commissionAmount} AS DECIMAL)), 0)`,
      })
      .from(affiliateCommissions)
      .where(eq(affiliateCommissions.affiliateId, affiliate.id))
      .groupBy(affiliateCommissions.status);

    // Get monthly earnings (last 6 months)
    const monthlyEarnings = await this.drizzle.db
      .select({
        month: sql<string>`TO_CHAR(${affiliateCommissions.createdAt}, 'YYYY-MM')`,
        earnings: sql<string>`COALESCE(SUM(CAST(${affiliateCommissions.commissionAmount} AS DECIMAL)), 0)`,
        orders: count(),
      })
      .from(affiliateCommissions)
      .where(
        and(
          eq(affiliateCommissions.affiliateId, affiliate.id),
          eq(affiliateCommissions.status, 'PENDING'),
          gte(affiliateCommissions.createdAt, sql`NOW() - INTERVAL '6 months'`),
        ),
      )
      .groupBy(sql`TO_CHAR(${affiliateCommissions.createdAt}, 'YYYY-MM')`)
      .orderBy(sql`TO_CHAR(${affiliateCommissions.createdAt}, 'YYYY-MM')`);

    // Get top customers
    const topCustomers = await this.drizzle.db
      .select({
        userId: promoCodeUsage.userId,
        userName: users.name,
        userPhone: users.phoneNumber,
        totalOrders: count(),
        totalSpent: sql<string>`COALESCE(SUM(CAST(${promoCodeUsage.orderAmount} AS DECIMAL)), 0)`,
      })
      .from(promoCodeUsage)
      .leftJoin(users, eq(users.id, promoCodeUsage.userId))
      .where(eq(promoCodeUsage.affiliateId, affiliate.id))
      .groupBy(promoCodeUsage.userId, users.name, users.phoneNumber)
      .orderBy(desc(count()))
      .limit(10);

    return {
      affiliate: {
        ...affiliate,
        totalEarnings: Number(affiliate.totalEarnings),
        paidEarnings: Number(affiliate.paidEarnings),
        pendingEarnings: Number(affiliate.pendingEarnings),
        commissionRate: Number(affiliate.commissionRate),
      },
      promoCodes: myPromoCodes.map((pc) => ({
        ...pc,
        discountValue: Number(pc.discountValue),
        totalRevenue: Number(pc.totalRevenue),
        totalDiscountGiven: Number(pc.totalDiscountGiven),
      })),
      commissionBreakdown: commissionStats.map((cs) => ({
        status: cs.status,
        count: cs.count,
        total: Number(cs.total),
      })),
      monthlyEarnings: monthlyEarnings.map((me) => ({
        month: me.month,
        earnings: Number(me.earnings),
        orders: me.orders,
      })),
      topCustomers: topCustomers.map((tc) => ({
        ...tc,
        totalSpent: Number(tc.totalSpent),
      })),
    };
  }

  // ==========================================
  // USER: Create Promo Code
  // ==========================================
  async createPromoCode(dto: CreatePromoCodeDto, userId: string) {
    // 1. Verify user is an approved affiliate
    const [affiliate] = await this.drizzle.db // ✅ FIXED: this.drizzle.db
      .select()
      .from(affiliates)
      .where(eq(affiliates.userId, userId));

    if (!affiliate)
      throw new ForbiddenException('You are not an approved affiliate');
    if (affiliate.status !== 'ACTIVE') {
      throw new ForbiddenException(
        'Your affiliate account is currently suspended.',
      );
    }
    // 2. Check for duplicate codes
    const [existing] = await this.drizzle.db // ✅ FIXED
      .select()
      .from(promoCodes)
      .where(sql`UPPER(${promoCodes.code}) = UPPER(${dto.code})`);

    if (existing) throw new ConflictException('This promo code already exists'); // ✅ ConflictException is now imported

    // 3. INSERT INTO DATABASE (FORCE isActive: false)
    const [newCode] = await this.drizzle.db // ✅ FIXED
      .insert(promoCodes)
      .values({
        id: uuidv4(),
        code: dto.code.toUpperCase().trim(),
        affiliateId: affiliate.id,
        description: dto.description || null,
        discountType: dto.discountType,
        discountValue: dto.discountValue.toString(),
        isActive: false, // 🔒 CRITICAL SECURITY: Affiliates CANNOT auto-activate codes
        usedCount: 0,
      })
      .returning();

    return { message: 'Promo code submitted for approval', promoCode: newCode };
  }

  async deletePromoCodeByAdmin(id: string) {
    // Check if code exists
    const [existing] = await this.drizzle.db
      .select()
      .from(promoCodes)
      .where(eq(promoCodes.id, id))
      .limit(1);

    if (!existing) throw new NotFoundException('Promo code not found');

    // Delete the promo code
    await this.drizzle.db.delete(promoCodes).where(eq(promoCodes.id, id));

    return { message: 'Promo code deleted successfully' };
  }
  // ==========================================
  // GET MY AFFILIATE STATS (Aggregated)
  // ==========================================
  async getMyAffiliateStats(userId: string) {
    const [affiliate] = await this.drizzle.db
      .select()
      .from(affiliates)
      .where(eq(affiliates.userId, userId))
      .limit(1);

    if (!affiliate) {
      return {
        isAffiliate: false,
        status: null,
        totalEarnings: '0.00',
        pendingEarnings: '0.00',
        paidEarnings: '0.00',
        totalOrders: 0,
        commissionRate: '5.00',
      };
    }

    const [stats] = await this.drizzle.db
      .select({
        totalEarnings: sql<number>`COALESCE(SUM(CAST(${affiliateCommissions.commissionAmount} AS NUMERIC)), 0)`,
        pendingEarnings: sql<number>`COALESCE(SUM(CASE WHEN ${affiliateCommissions.status} = 'PENDING' THEN CAST(${affiliateCommissions.commissionAmount} AS NUMERIC) ELSE 0 END), 0)`,
        paidEarnings: sql<number>`COALESCE(SUM(CASE WHEN ${affiliateCommissions.status} = 'PAID' THEN CAST(${affiliateCommissions.commissionAmount} AS NUMERIC) ELSE 0 END), 0)`,
        totalOrders: sql<number>`COUNT(${affiliateCommissions.id})::int`,
      })
      .from(affiliateCommissions)
      .where(eq(affiliateCommissions.affiliateId, affiliate.id));

    // ✅ FIX: Return a FLAT object so the Flutter UI can read it directly
    return {
      isAffiliate: true,
      status: affiliate.status,
      totalEarnings: Number(stats?.totalEarnings || 0).toFixed(2),
      pendingEarnings: Number(stats?.pendingEarnings || 0).toFixed(2),
      paidEarnings: Number(stats?.paidEarnings || 0).toFixed(2),
      totalOrders: stats?.totalOrders || 0,
      commissionRate: affiliate.commissionRate,
    };
  }

  // ==========================================
  // GET MY PROMO CODES (With Usage Stats)
  // ==========================================
  // ==========================================
  // GET MY PROMO CODES (Fixed to take userId)
  // ==========================================
  async getMyPromoCodes(userId: string) {
    // 1. Look up the affiliate ID for this user
    const [affiliate] = await this.drizzle.db
      .select()
      .from(affiliates)
      .where(eq(affiliates.userId, userId))
      .limit(1);

    if (!affiliate) return [];

    // 2. Fetch codes using the actual affiliate ID
    const codes = await this.drizzle.db
      .select()
      .from(promoCodes)
      .where(eq(promoCodes.affiliateId, affiliate.id))
      .orderBy(desc(promoCodes.createdAt));

    // 3. Calculate uses and revenue for EACH code from the commissions table
    const codesWithStats = await Promise.all(
      codes.map(async (code) => {
        const [usageStats] = await this.drizzle.db
          .select({
            usedCount: sql<number>`COUNT(${affiliateCommissions.id})::int`,
            totalRevenue: sql<number>`COALESCE(SUM(CAST(${affiliateCommissions.orderAmount} AS NUMERIC)), 0)`,
          })
          .from(affiliateCommissions)
          .where(eq(affiliateCommissions.promoCodeId, code.id));

        return {
          ...code,
          discountValue: Number(code.discountValue),
          usedCount: usageStats?.usedCount || 0,
          totalRevenue: Number(usageStats?.totalRevenue || 0).toFixed(2),
        };
      }),
    );

    return codesWithStats;
  }

  // ==========================================
  // GET MY COMMISSIONS (New Method)
  // ==========================================
  async getMyCommissions(userId: string, status?: string) {
    const [affiliate] = await this.drizzle.db
      .select()
      .from(affiliates)
      .where(eq(affiliates.userId, userId))
      .limit(1);

    if (!affiliate) return [];

    const conditions: SQL[] = [
      eq(affiliateCommissions.affiliateId, affiliate.id),
    ];
    if (status && status !== 'ALL') {
      conditions.push(eq(affiliateCommissions.status, status));
    }

    const commissions = await this.drizzle.db
      .select({
        id: affiliateCommissions.id,
        commissionRate: affiliateCommissions.commissionRate,
        commissionAmount: affiliateCommissions.commissionAmount,
        orderAmount: affiliateCommissions.orderAmount,
        status: affiliateCommissions.status,
        createdAt: affiliateCommissions.createdAt,
        order: {
          id: orders.id,
          orderNumber: orders.orderNumber,
          totalAmount: orders.totalAmount,
          status: orders.status,
        },
      })
      .from(affiliateCommissions)
      .leftJoin(orders, eq(orders.id, affiliateCommissions.orderId))
      .where(and(...conditions))
      .orderBy(desc(affiliateCommissions.createdAt))
      .limit(50);

    return commissions.map((c) => ({
      ...c,
      commissionRate: Number(c.commissionRate),
      commissionAmount: Number(c.commissionAmount),
      orderAmount: Number(c.orderAmount),
    }));
  }

  // ==========================================
  // USER: Update/Delete Promo Code
  // ==========================================
  async updatePromoCodeByAdmin(id: string, dto: UpdatePromoCodeDto) {
    const updateData: Record<string, unknown> = { updatedAt: new Date() };

    // ── Basic fields ─────────────────────────────────────────
    if (dto.description !== undefined) {
      updateData.description = dto.description;
    }

    if (dto.discountType !== undefined) {
      updateData.discountType = dto.discountType;
    }

    if (dto.discountValue !== undefined) {
      updateData.discountValue = dto.discountValue.toString();
    }

    if (dto.isActive !== undefined) {
      updateData.isActive = dto.isActive;
    }

    // ── Limits ───────────────────────────────────────────────
    if (dto.minOrderAmount !== undefined) {
      updateData.minOrderAmount =
        dto.minOrderAmount === null ? null : dto.minOrderAmount.toString();
    }

    if (dto.maxDiscountAmount !== undefined) {
      // ✅ FIXED: maxDiscountAmount now persisted
      updateData.maxDiscountAmount =
        dto.maxDiscountAmount === null
          ? null
          : dto.maxDiscountAmount.toString();
    }

    if (dto.maxUses !== undefined) {
      updateData.maxUses = dto.maxUses;
    }

    if (dto.maxUsesPerUser !== undefined) {
      // ✅ FIXED: maxUsesPerUser now persisted
      updateData.maxUsesPerUser = dto.maxUsesPerUser;
    }

    // ── Expiry date ──────────────────────────────────────────
    if (dto.expiresAt !== undefined) {
      // ✅ FIXED: null clears, string sets
      updateData.expiresAt = dto.expiresAt ? new Date(dto.expiresAt) : null;
    }

    // ── Perform update ───────────────────────────────────────
    const [updated] = await this.drizzle.db
      .update(promoCodes)
      .set(updateData)
      .where(eq(promoCodes.id, id))
      .returning();

    if (!updated) throw new NotFoundException('Promo code not found');

    // ── Notify affiliate if code was just activated ──────────
    if (dto.isActive === true && updated.affiliateId) {
      const affiliate = await this.drizzle.db.query.affiliates.findFirst({
        where: eq(affiliates.id, updated.affiliateId),
      });

      if (affiliate) {
        try {
          await this.notificationsService.create({
            userId: affiliate.userId,
            type: NotificationType.SYSTEM,
            title: '🎉 Promo Code Approved!',
            message: `Your promo code "${updated.code}" has been approved and is now active!`,
            actionText: 'View Codes',
            actionLink: '/affiliate/promo-codes',
          });

          this.chatGateway.server
            .to(`user:${affiliate.userId}`)
            .emit('new_notification', {
              title: '🎉 Promo Code Approved!',
              message: `Your code "${updated.code}" is now active!`,
              actionLink: '/affiliate/promo-codes',
            });
        } catch (err) {
          this.logger.error('Failed to send approval notification', err);
        }
      }
    }

    return {
      message: 'Promo code updated successfully',
      promoCode: updated,
    };
  }

  // ==========================================
  // USER: Update Promo Code (Before Approval)
  // ==========================================
  async updateMyPromoCode(
    userId: string,
    promoCodeId: string,
    dto: UpdatePromoCodeDto,
  ) {
    const affiliate = await this.drizzle.db.query.affiliates.findFirst({
      where: eq(affiliates.userId, userId),
    });

    if (!affiliate) {
      throw new ForbiddenException('You are not an affiliate');
    }

    const existing = await this.drizzle.db
      .select()
      .from(promoCodes)
      .where(
        and(
          eq(promoCodes.id, promoCodeId),
          eq(promoCodes.affiliateId, affiliate.id),
        ),
      )
      .limit(1);

    if (existing.length === 0) {
      throw new NotFoundException('Promo code not found');
    }

    const updateData: Record<string, unknown> = { updatedAt: new Date() };

    // Allow updating description
    if (dto.description !== undefined) updateData.description = dto.description;

    // Allow updating discount ONLY IF it hasn't been approved yet
    if (existing[0].isActive === false) {
      if (dto.discountValue !== undefined)
        updateData.discountValue = dto.discountValue.toString();
      if (dto.discountType !== undefined)
        updateData.discountType = dto.discountType;
    }

    // 🔒 SECURITY: We intentionally ignore dto.isActive, dto.maxUses, etc.
    // Regular users CANNOT activate their own codes or change limits via this endpoint.
    // Only the Super Admin can do that via `updatePromoCodeByAdmin`.

    const [updated] = await this.drizzle.db
      .update(promoCodes)
      .set(updateData)
      .where(eq(promoCodes.id, promoCodeId))
      .returning();

    return { message: 'Promo code updated', promoCode: updated };
  }
  async deleteMyPromoCode(userId: string, promoCodeId: string) {
    const affiliate = await this.drizzle.db.query.affiliates.findFirst({
      where: eq(affiliates.userId, userId),
    });

    if (!affiliate) {
      throw new ForbiddenException('You are not an affiliate');
    }

    const [deleted] = await this.drizzle.db
      .delete(promoCodes)
      .where(
        and(
          eq(promoCodes.id, promoCodeId),
          eq(promoCodes.affiliateId, affiliate.id),
        ),
      )
      .returning();

    if (!deleted) throw new NotFoundException('Promo code not found');

    return { message: 'Promo code deleted' };
  }

  // ==========================================
  // PUBLIC: Validate Promo Code (used during checkout)
  // ==========================================
  async validatePromoCode(code: string, orderAmount: number, userId: string) {
    console.log(
      '🎟️ [Service] Validating code:',
      code,
      'for amount:',
      orderAmount,
      'user:',
      userId,
    );

    const promo = await this.drizzle.db.query.promoCodes.findFirst({
      where: sql`UPPER(${promoCodes.code}) = UPPER(${code})`,
      with: { affiliate: true },
    });

    console.log('🎟️ [Service] Found promo:', promo ? 'YES' : 'NO');

    if (!promo) {
      console.log('❌ [Service] Promo code not found in database');
      return { valid: false, message: 'Invalid promo code' };
    }

    console.log('🎟️ [Service] Promo details:', {
      id: promo.id,
      code: promo.code,
      isActive: promo.isActive,
      expiresAt: promo.expiresAt,
      maxUses: promo.maxUses,
      usedCount: promo.usedCount,
    });

    // Check if active
    if (!promo.isActive) {
      console.log('❌ [Service] Promo is not active');
      return { valid: false, message: 'This promo code is no longer active' };
    }

    // Check expiry
    if (promo.expiresAt && new Date(promo.expiresAt) < new Date()) {
      console.log('❌ [Service] Promo has expired');
      return { valid: false, message: 'This promo code has expired' };
    }

    // Check max uses
    if (promo.maxUses && promo.usedCount >= promo.maxUses) {
      console.log('❌ [Service] Promo max uses reached');
      return {
        valid: false,
        message: 'This promo code has reached its maximum usage limit',
      };
    }

    // Check min order amount
    if (promo.minOrderAmount && orderAmount < Number(promo.minOrderAmount)) {
      console.log('❌ [Service] Order amount too low');
      return {
        valid: false,
        message: `Minimum order amount is $${Number(promo.minOrderAmount)}`,
      };
    }

    // Check per-user limit
    const userUsages = await this.drizzle.db
      .select({ count: count() })
      .from(promoCodeUsage)
      .where(
        and(
          eq(promoCodeUsage.promoCodeId, promo.id),
          eq(promoCodeUsage.userId, userId),
        ),
      );

    console.log('🎟️ [Service] User usage count:', userUsages[0]?.count);

    if (
      promo.maxUsesPerUser &&
      (userUsages[0]?.count || 0) >= promo.maxUsesPerUser
    ) {
      console.log('❌ [Service] User max uses reached');
      return {
        valid: false,
        message: `You have already used this promo code ${promo.maxUsesPerUser} time(s)`,
      };
    }

    // Check affiliate is active
    if (promo.affiliateId && promo.affiliate?.status !== 'ACTIVE') {
      console.log('❌ [Service] Affiliate not active');
      return {
        valid: false,
        message: 'This promo code is temporarily unavailable',
      };
    }

    // Calculate discount
    let discountAmount = 0;
    const discountValue = Number(promo.discountValue);

    if (promo.discountType === 'PERCENTAGE') {
      discountAmount = (orderAmount * discountValue) / 100;
      if (
        promo.maxDiscountAmount &&
        discountAmount > Number(promo.maxDiscountAmount)
      ) {
        discountAmount = Number(promo.maxDiscountAmount);
      }
    } else {
      discountAmount = discountValue;
    }

    // Don't allow discount to exceed order amount
    if (discountAmount > orderAmount) {
      discountAmount = orderAmount;
    }

    console.log('✅ [Service] Promo valid! Discount:', discountAmount);

    return {
      valid: true,
      promoCode: {
        id: promo.id,
        code: promo.code,
        discountType: promo.discountType,
        discountValue,
        discountAmount: Math.round(discountAmount * 100) / 100,
        affiliateId: promo.affiliateId,
        affiliateName: promo.affiliate
          ? `via ${promo.affiliate.uniqueCode}`
          : null,
      },
    };
  }
  // ==========================================
  // ORDER: Record Promo Code Usage & Commission
  // ==========================================
  // ==========================================
  // RECORD PROMO USAGE & GENERATE COMMISSION
  // ==========================================
  async recordPromoUsage(
    promoCodeId: string,
    userId: string,
    orderId: string,
    orderAmount: number,
    discountAmount: number,
  ) {
    const [promo] = await this.drizzle.db
      .select()
      .from(promoCodes)
      .where(eq(promoCodes.id, promoCodeId))
      .limit(1);

    if (!promo || !promo.affiliateId) {
      this.logger.warn(
        `Promo code ${promoCodeId} not found or has no affiliate`,
      );
      return;
    }

    // 1. Record usage
    await this.drizzle.db.insert(promoCodeUsage).values({
      promoCodeId: promoCodeId,
      userId: userId,
      orderId: orderId,
      orderAmount: orderAmount.toString(),
      discountAmount: discountAmount.toString(),
      createdAt: new Date(),
    });

    // 2. Increase used count
    await this.drizzle.db
      .update(promoCodes)
      .set({
        usedCount: sql`${promoCodes.usedCount} + 1`,
      })
      .where(eq(promoCodes.id, promoCodeId));

    // 3. Get affiliate
    const [affiliate] = await this.drizzle.db
      .select()
      .from(affiliates)
      .where(eq(affiliates.id, promo.affiliateId))
      .limit(1);

    if (!affiliate) {
      this.logger.warn(`Affiliate not found for promo code ${promoCodeId}`);
      return;
    }

    // 4. Calculate commission
    const commissionableAmount = Math.max(0, orderAmount - discountAmount);
    const rate = Number(affiliate.commissionRate) || 5;
    const commissionAmount = (commissionableAmount * rate) / 100;

    // 5. Insert commission
    await this.drizzle.db.insert(affiliateCommissions).values({
      affiliateId: affiliate.id,
      orderId: orderId,
      promoCodeId: promoCodeId,
      orderAmount: orderAmount.toString(),
      commissionRate: rate.toString(),
      commissionAmount: commissionAmount.toFixed(2),
      status: 'PENDING' as const,
      createdAt: new Date(),
    });

    // 6. Update affiliate wallet
    await this.drizzle.db
      .update(affiliates)
      .set({
        pendingEarnings: sql`${affiliates.pendingEarnings} + ${commissionAmount}`,
        totalEarnings: sql`${affiliates.totalEarnings} + ${commissionAmount}`,
      })
      .where(eq(affiliates.id, affiliate.id));

    this.logger.log(
      `💰 Commission recorded: $${commissionAmount.toFixed(2)} for affiliate ${affiliate.id} on order ${orderId}`,
    );

    // 7. Notify affiliate
    try {
      await this.notificationsService.create({
        userId: affiliate.userId,
        type: NotificationType.SYSTEM,
        title: '💰 New Commission Earned!',
        message: `You earned $${commissionAmount.toFixed(2)} commission on a recent order.`,
        actionText: 'View Stats',
        actionLink: '/affiliate/stats',
      });
    } catch (err) {
      this.logger.error('Failed to send commission notification', err);
    }
  }

  // ==========================================
  // ORDER: Cancel Commission (when order is cancelled)
  // ==========================================
  async cancelCommission(orderId: string) {
    return this.drizzle.db.transaction(async (tx) => {
      const commissions = await tx
        .select()
        .from(affiliateCommissions)
        .where(
          and(
            eq(affiliateCommissions.orderId, orderId),
            eq(affiliateCommissions.status, 'PENDING'),
          ),
        );

      for (const commission of commissions) {
        await tx
          .update(affiliateCommissions)
          .set({
            status: 'CANCELLED',
            cancelledAt: new Date(),
            cancellationReason: 'Order cancelled',
          })
          .where(eq(affiliateCommissions.id, commission.id));

        // Reverse affiliate earnings
        const commissionAmount = Number(commission.commissionAmount);
        await tx
          .update(affiliates)
          .set({
            totalEarnings: sql`GREATEST(CAST(${affiliates.totalEarnings} AS DECIMAL) - ${commissionAmount}, 0)`,
            pendingEarnings: sql`GREATEST(CAST(${affiliates.pendingEarnings} AS DECIMAL) - ${commissionAmount}, 0)`,
            totalOrders: sql`GREATEST(${affiliates.totalOrders} - 1, 0)`,
            updatedAt: new Date(),
          })
          .where(eq(affiliates.id, commission.affiliateId));
      }
    });
  }

  // ==========================================
  // SUPER ADMIN: Get All Affiliate Requests

  // ==========================================
  async getAffiliateRequests(
    status?: string,
    page: number = 1,
    limit: number = 20,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = [];

    if (status) {
      conditions.push(eq(affiliateRequests.status, status));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [items, totalResult] = await Promise.all([
      this.drizzle.db
        .select({
          id: affiliateRequests.id,
          businessName: affiliateRequests.businessName,
          description: affiliateRequests.description,
          phoneNumber: affiliateRequests.phoneNumber,
          socialMediaLinks: affiliateRequests.socialMediaLinks,
          expectedAudience: affiliateRequests.expectedAudience,
          status: affiliateRequests.status,
          rejectionReason: affiliateRequests.rejectionReason,
          appliedAt: affiliateRequests.appliedAt,
          reviewedAt: affiliateRequests.reviewedAt,
          user: {
            id: users.id,
            name: users.name,
            email: users.email,
            phoneNumber: users.phoneNumber,
            profileImage: users.profileImage,
          },
        })
        .from(affiliateRequests)
        .leftJoin(users, eq(users.id, affiliateRequests.userId))
        .where(whereClause)
        .orderBy(desc(affiliateRequests.createdAt))
        .limit(limit)
        .offset(offset),
      this.drizzle.db
        .select({ count: count() })
        .from(affiliateRequests)
        .where(whereClause),
    ]);

    const total = totalResult[0]?.count || 0;

    return {
      items,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // ==========================================
  // SUPER ADMIN: Approve Affiliate Request
  // ==========================================
  async approveAffiliateRequest(
    requestId: string,
    adminUserId: string,
    dto: ReviewAffiliateRequestDto,
  ) {
    const [request] = await this.drizzle.db
      .select()
      .from(affiliateRequests)
      .where(eq(affiliateRequests.id, requestId))
      .limit(1);

    if (!request) throw new NotFoundException('Request not found');
    if (request.status !== 'PENDING') {
      throw new BadRequestException('This request has already been reviewed');
    }

    // Check if user already has affiliate account
    const existingAffiliate = await this.drizzle.db
      .select()
      .from(affiliates)
      .where(eq(affiliates.userId, request.userId))
      .limit(1);

    if (existingAffiliate.length > 0) {
      throw new BadRequestException('User is already an affiliate');
    }

    return this.drizzle.db.transaction(async (tx) => {
      // Generate unique affiliate code
      const uniqueCode = await this.generateUniqueAffiliateCode(
        request.businessName,
        tx,
      );

      // Create affiliate record
      const [affiliate] = await tx
        .insert(affiliates)
        .values({
          id: uuidv4(),
          userId: request.userId,
          uniqueCode,
          commissionRate: (dto.commissionRate || 5).toString(),
          status: 'ACTIVE',
        })
        .returning();

      // Update request status
      await tx
        .update(affiliateRequests)
        .set({
          status: 'APPROVED',
          reviewedBy: adminUserId,
          reviewedAt: new Date(),
          updatedAt: new Date(),
        })
        .where(eq(affiliateRequests.id, requestId));

      // Create default promo code for the affiliate
      await tx.insert(promoCodes).values({
        id: uuidv4(),
        code: uniqueCode,
        affiliateId: affiliate.id,
        description: `Welcome promo code for ${request.businessName}`,
        discountType: 'PERCENTAGE',
        discountValue: (dto.commissionRate || 5).toString(),
        isActive: true,
      });

      // Notify the user
      await this.notificationsService.create({
        userId: request.userId,
        type: NotificationType.SYSTEM,
        title: '🎉 Affiliate Application Approved!',
        message: `Congratulations! Your affiliate application for "${request.businessName}" has been approved. Your unique code is: ${uniqueCode}. Commission rate: ${dto.commissionRate || 5}%`,
        actionText: 'Start Earning',
        actionLink: '/affiliate/dashboard',
      });

      // Real-time notification
      this.chatGateway.server
        .to(`user:${request.userId}`)
        .emit('new_notification', {
          title: '🎉 Affiliate Approved!',
          message: `Your affiliate application has been approved! Code: ${uniqueCode}`,
          actionLink: '/affiliate/dashboard',
        });

      return {
        message: 'Affiliate request approved successfully',
        affiliate: {
          ...affiliate,
          commissionRate: Number(affiliate.commissionRate),
        },
      };
    });
  }

  // ==========================================
  // SUPER ADMIN: Reject Affiliate Request
  // ==========================================
  async rejectAffiliateRequest(
    requestId: string,
    adminUserId: string,
    dto: RejectAffiliateRequestDto,
  ) {
    const [request] = await this.drizzle.db
      .select()
      .from(affiliateRequests)
      .where(eq(affiliateRequests.id, requestId))
      .limit(1);

    if (!request) throw new NotFoundException('Request not found');
    if (request.status !== 'PENDING') {
      throw new BadRequestException('This request has already been reviewed');
    }

    await this.drizzle.db
      .update(affiliateRequests)
      .set({
        status: 'REJECTED',
        rejectionReason: dto.rejectionReason,
        reviewedBy: adminUserId,
        reviewedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(affiliateRequests.id, requestId));

    // Notify user
    await this.notificationsService.create({
      userId: request.userId,
      type: NotificationType.SYSTEM,
      title: '❌ Affiliate Application Declined',
      message: `Your application for "${request.businessName}" was not approved. Reason: ${dto.rejectionReason}`,
      actionText: 'View Details',
      actionLink: '/affiliate/status',
    });

    return { message: 'Affiliate request rejected' };
  }

  // ==========================================
  // SUPER ADMIN: Get All Affiliates
  // ==========================================
  // ==========================================
  // SUPER ADMIN: Get All Affiliates
  // ==========================================
  async getAllAffiliates(
    status?: string,
    search?: string,
    page: number = 1,
    limit: number = 20,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = []; // ✅ FIXED: Explicitly typed as SQL[]

    if (status) {
      conditions.push(eq(affiliates.status, status));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [items, totalResult] = await Promise.all([
      this.drizzle.db
        .select({
          id: affiliates.id,
          uniqueCode: affiliates.uniqueCode,
          commissionRate: affiliates.commissionRate,
          totalEarnings: affiliates.totalEarnings,
          paidEarnings: affiliates.paidEarnings,
          pendingEarnings: affiliates.pendingEarnings,
          totalOrders: affiliates.totalOrders,
          totalCustomers: affiliates.totalCustomers,
          status: affiliates.status,
          joinedAt: affiliates.joinedAt,
          user: {
            id: users.id,
            name: users.name,
            email: users.email,
            phoneNumber: users.phoneNumber,
            profileImage: users.profileImage,
          },
          promoCodesCount: sql<number>`(SELECT COUNT(*) FROM promo_codes WHERE affiliate_id = ${affiliates.id})::int`,
          activePromoCodes: sql<number>`(SELECT COUNT(*) FROM promo_codes WHERE affiliate_id = ${affiliates.id} AND is_active = true)::int`,
        })
        .from(affiliates)
        .leftJoin(users, eq(users.id, affiliates.userId))
        .where(whereClause)
        .orderBy(desc(affiliates.totalEarnings))
        .limit(limit)
        .offset(offset),
      this.drizzle.db
        .select({ count: count() })
        .from(affiliates)
        .where(whereClause),
    ]);

    const total = totalResult[0]?.count || 0;

    return {
      items: items.map((item) => ({
        ...item,
        commissionRate: Number(item.commissionRate),
        totalEarnings: Number(item.totalEarnings),
        paidEarnings: Number(item.paidEarnings),
        pendingEarnings: Number(item.pendingEarnings),
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
  // ==========================================
  // SUPER ADMIN: Get Affiliate Detail
  // ==========================================
  async getAffiliateDetail(affiliateId: string) {
    const affiliate = await this.drizzle.db.query.affiliates.findFirst({
      where: eq(affiliates.id, affiliateId),
      with: {
        user: {
          columns: {
            id: true,
            name: true,
            email: true,
            phoneNumber: true,
            profileImage: true,
          },
        },
        promoCodes: {
          orderBy: [desc(promoCodes.createdAt)],
        },
        commissions: {
          orderBy: [desc(affiliateCommissions.createdAt)],
          limit: 50,
          with: {
            order: {
              columns: {
                id: true,
                orderNumber: true,
                totalAmount: true,
                status: true,
              },
            },
          },
        },
      },
    });

    if (!affiliate) throw new NotFoundException('Affiliate not found');

    // Get usage stats per promo code
    const promoStats = await this.drizzle.db
      .select({
        promoCodeId: promoCodeUsage.promoCodeId,
        code: promoCodes.code,
        totalUses: count(),
        totalRevenue: sql<string>`COALESCE(SUM(CAST(${promoCodeUsage.orderAmount} AS DECIMAL)), 0)`,
        totalDiscount: sql<string>`COALESCE(SUM(CAST(${promoCodeUsage.discountAmount} AS DECIMAL)), 0)`,
        uniqueUsers: sql<number>`COUNT(DISTINCT ${promoCodeUsage.userId})::int`,
      })
      .from(promoCodeUsage)
      .leftJoin(promoCodes, eq(promoCodes.id, promoCodeUsage.promoCodeId))
      .where(eq(promoCodeUsage.affiliateId, affiliateId))
      .groupBy(promoCodeUsage.promoCodeId, promoCodes.code)
      .orderBy(desc(count()));

    // Monthly performance (last 12 months)
    const monthlyPerformance = await this.drizzle.db
      .select({
        month: sql<string>`TO_CHAR(${affiliateCommissions.createdAt}, 'YYYY-MM')`,
        totalOrders: count(),
        totalCommission: sql<string>`COALESCE(SUM(CAST(${affiliateCommissions.commissionAmount} AS DECIMAL)), 0)`,
        totalRevenue: sql<string>`COALESCE(SUM(CAST(${affiliateCommissions.orderAmount} AS DECIMAL)), 0)`,
      })
      .from(affiliateCommissions)
      .where(
        and(
          eq(affiliateCommissions.affiliateId, affiliateId),
          gte(
            affiliateCommissions.createdAt,
            sql`NOW() - INTERVAL '12 months'`,
          ),
        ),
      )
      .groupBy(sql`TO_CHAR(${affiliateCommissions.createdAt}, 'YYYY-MM')`)
      .orderBy(sql`TO_CHAR(${affiliateCommissions.createdAt}, 'YYYY-MM')`);

    // Top customers referred
    const topCustomers = await this.drizzle.db
      .select({
        userId: promoCodeUsage.userId,
        userName: users.name,
        userPhone: users.phoneNumber,
        totalOrders: count(),
        totalSpent: sql<string>`COALESCE(SUM(CAST(${promoCodeUsage.orderAmount} AS DECIMAL)), 0)`,
      })
      .from(promoCodeUsage)
      .leftJoin(users, eq(users.id, promoCodeUsage.userId))
      .where(eq(promoCodeUsage.affiliateId, affiliateId))
      .groupBy(promoCodeUsage.userId, users.name, users.phoneNumber)
      .orderBy(desc(count()))
      .limit(20);

    return {
      affiliate: {
        ...affiliate,
        commissionRate: Number(affiliate.commissionRate),
        totalEarnings: Number(affiliate.totalEarnings),
        paidEarnings: Number(affiliate.paidEarnings),
        pendingEarnings: Number(affiliate.pendingEarnings),
        promoCodes: affiliate.promoCodes.map((pc) => ({
          ...pc,
          discountValue: Number(pc.discountValue),
        })),
        commissions: affiliate.commissions.map((c) => ({
          ...c,
          commissionRate: Number(c.commissionRate),
          commissionAmount: Number(c.commissionAmount),
          orderAmount: Number(c.orderAmount),
        })),
      },
      promoStats: promoStats.map((ps) => ({
        ...ps,
        totalRevenue: Number(ps.totalRevenue),
        totalDiscount: Number(ps.totalDiscount),
      })),
      monthlyPerformance: monthlyPerformance.map((mp) => ({
        ...mp,
        totalCommission: Number(mp.totalCommission),
        totalRevenue: Number(mp.totalRevenue),
      })),
      topCustomers: topCustomers.map((tc) => ({
        ...tc,
        totalSpent: Number(tc.totalSpent),
      })),
    };
  }

  // ==========================================
  // SUPER ADMIN: Update Affiliate
  // ==========================================
  async updateAffiliate(affiliateId: string, dto: UpdateAffiliateDto) {
    const updateData: Record<string, unknown> = { updatedAt: new Date() };

    if (dto.commissionRate !== undefined) {
      updateData.commissionRate = dto.commissionRate.toString();
    }
    if (dto.status !== undefined) {
      updateData.status = dto.status;
    }

    const [updated] = await this.drizzle.db
      .update(affiliates)
      .set(updateData)
      .where(eq(affiliates.id, affiliateId))
      .returning();

    if (!updated) throw new NotFoundException('Affiliate not found');

    // Notify affiliate
    await this.notificationsService.create({
      userId: updated.userId,
      type: NotificationType.SYSTEM,
      title:
        dto.status === 'SUSPENDED'
          ? '⚠️ Affiliate Account Suspended'
          : '✅ Affiliate Account Updated',
      message:
        dto.status === 'SUSPENDED'
          ? 'Your affiliate account has been suspended. Contact support for more information.'
          : dto.commissionRate
            ? `Your commission rate has been updated to ${dto.commissionRate}%`
            : 'Your affiliate account has been updated',
      actionText: 'View Details',
      actionLink: '/affiliate/status',
    });

    return {
      message: 'Affiliate updated successfully',
      affiliate: {
        ...updated,
        commissionRate: Number(updated.commissionRate),
      },
    };
  }

  // ==========================================
  // SUPER ADMIN: Affiliate Dashboard
  // ==========================================
  async getAffiliateDashboard() {
    const [
      totalAffiliates,
      pendingRequests,
      totalEarnings,
      totalPendingCommissions,
      totalPaidCommissions,
      totalOrdersViaAffiliates,
      topAffiliates,
      recentRequests,
      recentCommissions,
      monthlyStats,
    ] = await Promise.all([
      // Total active affiliates
      this.drizzle.db
        .select({ count: count() })
        .from(affiliates)
        .where(eq(affiliates.status, 'ACTIVE')),

      // Pending requests
      this.drizzle.db
        .select({ count: count() })
        .from(affiliateRequests)
        .where(eq(affiliateRequests.status, 'PENDING')),

      // Total earnings paid to all affiliates
      this.drizzle.db
        .select({
          total: sql<string>`COALESCE(SUM(CAST(${affiliates.totalEarnings} AS DECIMAL)), 0)`,
        })
        .from(affiliates),

      // Total pending commissions
      this.drizzle.db
        .select({
          total: sql<string>`COALESCE(SUM(CAST(${affiliateCommissions.commissionAmount} AS DECIMAL)), 0)`,
        })
        .from(affiliateCommissions)
        .where(eq(affiliateCommissions.status, 'PENDING')),

      // Total paid commissions
      this.drizzle.db
        .select({
          total: sql<string>`COALESCE(SUM(CAST(${affiliateCommissions.commissionAmount} AS DECIMAL)), 0)`,
        })
        .from(affiliateCommissions)
        .where(eq(affiliateCommissions.status, 'PAID')),

      // Total orders via affiliates
      this.drizzle.db.select({ count: count() }).from(affiliateCommissions),

      // Top 10 affiliates
      this.drizzle.db
        .select({
          id: affiliates.id,
          uniqueCode: affiliates.uniqueCode,
          userName: users.name,
          userImage: users.profileImage,
          totalEarnings: affiliates.totalEarnings,
          totalOrders: affiliates.totalOrders,
          totalCustomers: affiliates.totalCustomers,
          commissionRate: affiliates.commissionRate,
        })
        .from(affiliates)
        .leftJoin(users, eq(users.id, affiliates.userId))
        .where(eq(affiliates.status, 'ACTIVE'))
        .orderBy(desc(sql`CAST(${affiliates.totalEarnings} AS DECIMAL)`))
        .limit(10),

      // Recent 10 requests
      this.drizzle.db
        .select({
          id: affiliateRequests.id,
          businessName: affiliateRequests.businessName,
          status: affiliateRequests.status,
          appliedAt: affiliateRequests.appliedAt,
          userName: users.name,
          userPhone: users.phoneNumber,
        })
        .from(affiliateRequests)
        .leftJoin(users, eq(users.id, affiliateRequests.userId))
        .orderBy(desc(affiliateRequests.createdAt))
        .limit(10),

      // Recent commissions
      this.drizzle.db
        .select({
          id: affiliateCommissions.id,
          affiliateCode: affiliates.uniqueCode,
          affiliateName: users.name,
          commissionAmount: affiliateCommissions.commissionAmount,
          orderAmount: affiliateCommissions.orderAmount,
          status: affiliateCommissions.status,
          createdAt: affiliateCommissions.createdAt,
        })
        .from(affiliateCommissions)
        .leftJoin(
          affiliates,
          eq(affiliates.id, affiliateCommissions.affiliateId),
        )
        .leftJoin(users, eq(users.id, affiliates.userId))
        .orderBy(desc(affiliateCommissions.createdAt))
        .limit(10),

      // Monthly stats (last 6 months)
      this.drizzle.db
        .select({
          month: sql<string>`TO_CHAR(${affiliateCommissions.createdAt}, 'YYYY-MM')`,
          totalCommissions: sql<string>`COALESCE(SUM(CAST(${affiliateCommissions.commissionAmount} AS DECIMAL)), 0)`,
          totalOrders: count(),
          totalRevenue: sql<string>`COALESCE(SUM(CAST(${affiliateCommissions.orderAmount} AS DECIMAL)), 0)`,
        })
        .from(affiliateCommissions)
        .where(
          gte(affiliateCommissions.createdAt, sql`NOW() - INTERVAL '6 months'`),
        )
        .groupBy(sql`TO_CHAR(${affiliateCommissions.createdAt}, 'YYYY-MM')`)
        .orderBy(sql`TO_CHAR(${affiliateCommissions.createdAt}, 'YYYY-MM')`),
    ]);

    return {
      summary: {
        totalAffiliates: totalAffiliates[0]?.count || 0,
        pendingRequests: pendingRequests[0]?.count || 0,
        totalEarningsPaid: Number(totalEarnings[0]?.total || 0),
        totalPendingCommissions: Number(totalPendingCommissions[0]?.total || 0),
        totalPaidCommissions: Number(totalPaidCommissions[0]?.total || 0),
        totalOrdersViaAffiliates: totalOrdersViaAffiliates[0]?.count || 0,
      },
      topAffiliates: topAffiliates.map((ta) => ({
        ...ta,
        totalEarnings: Number(ta.totalEarnings),
        commissionRate: Number(ta.commissionRate),
      })),
      recentRequests,
      recentCommissions: recentCommissions.map((rc) => ({
        ...rc,
        commissionAmount: Number(rc.commissionAmount),
        orderAmount: Number(rc.orderAmount),
      })),
      monthlyStats: monthlyStats.map((ms) => ({
        ...ms,
        totalCommissions: Number(ms.totalCommissions),
        totalRevenue: Number(ms.totalRevenue),
      })),
    };
  }

  // ==========================================
  // SUPER ADMIN: Get All Commissions
  // ==========================================
  // ==========================================
  // SUPER ADMIN: Get All Commissions
  // ==========================================
  async getAllCommissions(
    status?: string,
    affiliateId?: string,
    page: number = 1,
    limit: number = 50,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = []; // ✅ FIXED: Explicitly typed as SQL[]

    if (status) conditions.push(eq(affiliateCommissions.status, status));
    if (affiliateId)
      conditions.push(eq(affiliateCommissions.affiliateId, affiliateId));

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [items, totalResult, summaryResult] = await Promise.all([
      this.drizzle.db
        .select({
          id: affiliateCommissions.id,
          commissionRate: affiliateCommissions.commissionRate,
          commissionAmount: affiliateCommissions.commissionAmount,
          orderAmount: affiliateCommissions.orderAmount,
          status: affiliateCommissions.status,
          paidAt: affiliateCommissions.paidAt,
          createdAt: affiliateCommissions.createdAt,
          affiliateCode: affiliates.uniqueCode,
          affiliateName: users.name,
          affiliatePhone: users.phoneNumber,
          orderNumber: orders.orderNumber,
        })
        .from(affiliateCommissions)
        .leftJoin(
          affiliates,
          eq(affiliates.id, affiliateCommissions.affiliateId),
        )
        .leftJoin(users, eq(users.id, affiliates.userId))
        .leftJoin(orders, eq(orders.id, affiliateCommissions.orderId))
        .where(whereClause)
        .orderBy(desc(affiliateCommissions.createdAt))
        .limit(limit)
        .offset(offset),
      this.drizzle.db
        .select({ count: count() })
        .from(affiliateCommissions)
        .where(whereClause),
      this.drizzle.db
        .select({
          pendingTotal: sql<string>`COALESCE(SUM(CASE WHEN ${affiliateCommissions.status} = 'PENDING' THEN CAST(${affiliateCommissions.commissionAmount} AS DECIMAL) ELSE 0 END), 0)`,
          paidTotal: sql<string>`COALESCE(SUM(CASE WHEN ${affiliateCommissions.status} = 'PAID' THEN CAST(${affiliateCommissions.commissionAmount} AS DECIMAL) ELSE 0 END), 0)`,
          cancelledTotal: sql<string>`COALESCE(SUM(CASE WHEN ${affiliateCommissions.status} = 'CANCELLED' THEN CAST(${affiliateCommissions.commissionAmount} AS DECIMAL) ELSE 0 END), 0)`,
        })
        .from(affiliateCommissions)
        .where(whereClause),
    ]);

    return {
      items: items.map((item) => ({
        ...item,
        commissionRate: Number(item.commissionRate),
        commissionAmount: Number(item.commissionAmount),
        orderAmount: Number(item.orderAmount),
      })),
      summary: {
        pendingTotal: Number(summaryResult[0]?.pendingTotal || 0),
        paidTotal: Number(summaryResult[0]?.paidTotal || 0),
        cancelledTotal: Number(summaryResult[0]?.cancelledTotal || 0),
      },
      pagination: {
        page,
        limit,
        total: totalResult[0]?.count || 0,
        totalPages: Math.ceil((totalResult[0]?.count || 0) / limit),
      },
    };
  }

  // ==========================================
  // SUPER ADMIN: Pay Commissions
  // ==========================================
  // affiliate.service.ts — replace the ENTIRE existing payCommissions method

  async payCommissions(dto: PayCommissionDto) {
    // ── Step 1: Load pending commissions ──────────────────────
    const commissions = await this.drizzle.db
      .select()
      .from(affiliateCommissions)
      .where(
        and(
          inArray(affiliateCommissions.id, dto.commissionIds),
          eq(affiliateCommissions.status, 'PENDING'),
        ),
      );

    if (commissions.length === 0) {
      throw new BadRequestException('No pending commissions found to pay');
    }

    // ── Step 2: Group by affiliate & enrich with phone ────────
    const affiliateTotals = new Map<string, number>();
    for (const c of commissions) {
      const amt = Number(c.commissionAmount);
      affiliateTotals.set(
        c.affiliateId,
        (affiliateTotals.get(c.affiliateId) ?? 0) + amt,
      );
    }

    const affiliateDetails = new Map<
      string,
      {
        userId: string;
        phone: string | null;
        name: string | null;
        total: number;
      }
    >();

    for (const [affiliateId, total] of affiliateTotals) {
      const info = await this._getAffiliatePhone(affiliateId);
      if (!info) {
        throw new NotFoundException(`Affiliate ${affiliateId} not found`);
      }
      affiliateDetails.set(affiliateId, {
        userId: info.userId,
        phone: info.phoneNumber,
        name: info.name,
        total,
      });
    }

    // ── Step 3: Send real money via WaafiPay for each affiliate ─
    const payouts: Array<{
      affiliateId: string;
      success: boolean;
      amount: number;
      transactionId?: string;
      error?: string;
    }> = [];

    for (const [affiliateId, detail] of affiliateDetails) {
      if (!detail.phone) {
        this.logger.warn(
          `⚠️ Affiliate ${affiliateId} has no phone number — skipping payout`,
        );
        payouts.push({
          affiliateId,
          success: false,
          amount: detail.total,
          error: 'No phone number on file',
        });
        continue;
      }

      const referenceId = `PAYOUT-${affiliateId.slice(0, 8)}-${Date.now()}`;

      const result = await this.waafiPayService.transferToWallet({
        amount: detail.total,
        phoneNumber: detail.phone,
        referenceId,
        description: `Affiliate commission payout for ${detail.name ?? 'affiliate'}`,
      });

      payouts.push({
        affiliateId,
        success: result.success,
        amount: detail.total,
        transactionId: result.transactionId,
        error: result.success ? undefined : result.message,
      });
    }

    // ── Step 4: If ANY payout failed, abort and report ─────────
    const failed = payouts.filter((p) => !p.success);
    if (failed.length > 0) {
      this.logger.error(
        `❌ ${failed.length} payout(s) failed: ${JSON.stringify(failed)}`,
      );
      throw new BadRequestException(
        `Payout failed for ${failed.length} affiliate(s). ` +
          failed.map((f) => `${f.affiliateId}: ${f.error}`).join(' | '),
      );
    }

    // ── Step 5: All payouts succeeded → mark DB as PAID ────────
    const now = new Date();

    await this.drizzle.db.transaction(async (tx) => {
      // 5a. Mark commissions PAID
      await tx
        .update(affiliateCommissions)
        .set({ status: 'PAID', paidAt: now })
        .where(inArray(affiliateCommissions.id, dto.commissionIds));

      // 5b. Update each affiliate's balances
      for (const [affiliateId, detail] of affiliateDetails) {
        await tx
          .update(affiliates)
          .set({
            paidEarnings: sql`CAST(${affiliates.paidEarnings} AS DECIMAL) + ${detail.total}`,
            pendingEarnings: sql`GREATEST(CAST(${affiliates.pendingEarnings} AS DECIMAL) - ${detail.total}, 0)`,
            updatedAt: now,
          })
          .where(eq(affiliates.id, affiliateId));
      }
    });

    // ── Step 6: Send notifications ─────────────────────────────
    for (const [affiliateId, detail] of affiliateDetails) {
      const payoutInfo = payouts.find((p) => p.affiliateId === affiliateId);

      try {
        await this.notificationsService.create({
          userId: detail.userId,
          type: NotificationType.SYSTEM,
          title: '💸 Payment Sent!',
          message: `$${detail.total.toFixed(2)} has been sent to your mobile wallet (${
            detail.phone
              ? detail.phone.slice(-4).padStart(detail.phone.length, '*')
              : ''
          }). ${dto.paymentNote || ''}`,
          actionText: 'View Earnings',
          actionLink: '/affiliate/stats',
        });

        this.chatGateway.server
          .to(`user:${detail.userId}`)
          .emit('new_notification', {
            title: '💸 Commission Paid',
            message: `$${detail.total.toFixed(2)} sent to your wallet`,
            actionLink: '/affiliate/stats',
          });
      } catch (err) {
        this.logger.warn('Failed to send payout notification', err);
      }
    }

    // ── Step 7: Return summary ─────────────────────────────────
    const totalPaid = Array.from(affiliateTotals.values()).reduce(
      (a, b) => a + b,
      0,
    );

    return {
      message: `${commissions.length} commission(s) paid — real money sent to ${affiliateDetails.size} affiliate(s)`,
      totalPaid,
      commissionsPaid: commissions.length,
      payouts: payouts.map((p) => ({
        affiliateId: p.affiliateId,
        amount: p.amount,
        transactionId: p.transactionId,
      })),
    };
  }

  // ==========================================
  // SUPER ADMIN: Create System-Wide Promo Code
  // ==========================================
  async createSystemPromoCode(dto: CreatePromoCodeDto) {
    const existingCode = await this.drizzle.db
      .select()
      .from(promoCodes)
      .where(sql`UPPER(${promoCodes.code}) = UPPER(${dto.code})`)
      .limit(1);

    if (existingCode.length > 0) {
      throw new BadRequestException('This promo code already exists');
    }

    const [promoCode] = await this.drizzle.db
      .insert(promoCodes)
      .values({
        id: uuidv4(),
        code: dto.code.toUpperCase().trim(),
        affiliateId: null, // System-wide
        description: dto.description || null,
        discountType: dto.discountType,
        discountValue: dto.discountValue.toString(),
        minOrderAmount: dto.minOrderAmount?.toString() || null,
        maxDiscountAmount: dto.maxDiscountAmount?.toString() || null,
        maxUses: dto.maxUses || null,
        maxUsesPerUser: dto.maxUsesPerUser || 1,
        isActive: true,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
      })
      .returning();

    return { message: 'System promo code created', promoCode };
  }

  // ==========================================
  // SUPER ADMIN: Get All Promo Codes
  // ==========================================

  // ==========================================
  // SUPER ADMIN: Get All Promo Codes
  // ==========================================
  async getAllPromoCodes(
    type?: 'system' | 'affiliate',
    isActive?: boolean,
    page: number = 1,
    limit: number = 50,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = []; // ✅ FIXED: Explicitly typed as SQL[]

    if (type === 'system') {
      conditions.push(sql`${promoCodes.affiliateId} IS NULL`);
    } else if (type === 'affiliate') {
      conditions.push(sql`${promoCodes.affiliateId} IS NOT NULL`);
    }

    if (isActive !== undefined) {
      conditions.push(eq(promoCodes.isActive, isActive));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [items, totalResult] = await Promise.all([
      this.drizzle.db
        .select({
          id: promoCodes.id,
          code: promoCodes.code,
          description: promoCodes.description,
          discountType: promoCodes.discountType,
          discountValue: promoCodes.discountValue,
          minOrderAmount: promoCodes.minOrderAmount,
          maxDiscountAmount: promoCodes.maxDiscountAmount,
          maxUses: promoCodes.maxUses,
          usedCount: promoCodes.usedCount,
          maxUsesPerUser: promoCodes.maxUsesPerUser,
          isActive: promoCodes.isActive,
          expiresAt: promoCodes.expiresAt,
          createdAt: promoCodes.createdAt,
          affiliateId: promoCodes.affiliateId,
          affiliateCode: affiliates.uniqueCode,
          affiliateName: users.name,
          totalRevenue: sql<string>`COALESCE((SELECT SUM(CAST(order_amount AS DECIMAL)) FROM promo_code_usage WHERE promo_code_id = ${promoCodes.id}), 0)`,
          totalDiscountGiven: sql<string>`COALESCE((SELECT SUM(CAST(discount_amount AS DECIMAL)) FROM promo_code_usage WHERE promo_code_id = ${promoCodes.id}), 0)`,
        })
        .from(promoCodes)
        .leftJoin(affiliates, eq(affiliates.id, promoCodes.affiliateId))
        .leftJoin(users, eq(users.id, affiliates.userId))
        .where(whereClause)
        .orderBy(desc(promoCodes.createdAt))
        .limit(limit)
        .offset(offset),
      this.drizzle.db
        .select({ count: count() })
        .from(promoCodes)
        .where(whereClause),
    ]);

    return {
      items: items.map((item) => ({
        ...item,
        discountValue: Number(item.discountValue),
        minOrderAmount: item.minOrderAmount
          ? Number(item.minOrderAmount)
          : null,
        maxDiscountAmount: item.maxDiscountAmount
          ? Number(item.maxDiscountAmount)
          : null,
        totalRevenue: Number(item.totalRevenue),
        totalDiscountGiven: Number(item.totalDiscountGiven),
      })),
      pagination: {
        page,
        limit,
        total: totalResult[0]?.count || 0,
        totalPages: Math.ceil((totalResult[0]?.count || 0) / limit),
      },
    };
  }

  // ==========================================
  // HELPERS
  // ==========================================
  private async generateUniqueAffiliateCode(
    businessName: string,
    tx: any,
  ): Promise<string> {
    const prefix = businessName
      .replace(/[^a-zA-Z0-9]/g, '')
      .substring(0, 4)
      .toUpperCase();

    let code = '';
    let isUnique = false;

    while (!isUnique) {
      const random = Math.random().toString(36).substring(2, 6).toUpperCase();
      code = `${prefix}-${random}`;

      const existing = await tx
        .select()
        .from(affiliates)
        .where(eq(affiliates.uniqueCode, code))
        .limit(1);

      if (existing.length === 0) isUnique = true;
    }

    return code;
  }

  private async _getAffiliatePhone(affiliateId: string): Promise<{
    userId: string;
    phoneNumber: string | null;
    name: string | null;
  } | null> {
    const [row] = await this.drizzle.db
      .select({
        userId: users.id,
        phoneNumber: users.phoneNumber,
        name: users.name,
      })
      .from(affiliates)
      .innerJoin(users, eq(users.id, affiliates.userId))
      .where(eq(affiliates.id, affiliateId))
      .limit(1);

    return row ?? null;
  }

  private async notifySuperAdmins(type: string, data: any) {
    try {
      // Emit to all connected super admins via WebSocket
      this.chatGateway.server.to('super_admins').emit('new_notification', {
        id: uuidv4(),
        type,
        ...data,
        createdAt: new Date().toISOString(),
        isRead: false,
      });
    } catch (error) {
      this.logger.error('Failed to notify super admins', error);
    }
  }

  private _serializeSettings(row: any) {
    return {
      defaultCommissionRate: Number(row.defaultCommissionRate ?? '5.00'),
      minPayoutAmount: Number(row.minPayoutAmount ?? '10.00'),
      payoutCycleDays: row.payoutCycleDays ?? 30,

      defaultDiscountType: row.defaultDiscountType ?? 'PERCENTAGE',
      defaultDiscountValue: Number(row.defaultDiscountValue ?? '5.00'),
      defaultMaxUsesPerUser: row.defaultMaxUsesPerUser ?? 1,

      requireApproval: row.requireApproval ?? true,
      autoApprovePromoCodes: row.autoApprovePromoCodes ?? false,
      allowSelfReferral: row.allowSelfReferral ?? false,
      cookieWindowDays: row.cookieWindowDays ?? 30,

      notifyOnNewApplication: row.notifyOnNewApplication ?? true,
      notifyOnNewCommission: row.notifyOnNewCommission ?? true,
      notifyOnCodeApproval: row.notifyOnCodeApproval ?? true,
      emailDigest: row.emailDigest ?? false,
    };
  }
}
