// src/markets/markets.service.ts
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { markets, users } from '../drizzle/schema';
import { sql, eq, and, or, like, desc, asc } from 'drizzle-orm';
import { LogSanitizer } from '../common/utils/log-sanitizer.util';

export interface MarketQueryParams {
  page?: number;
  limit?: number;
  search?: string;
  city?: string;
  sortBy?: 'name' | 'createdAt' | 'userCount';
  sortOrder?: 'asc' | 'desc';
}

export interface MarketResponse {
  id: string;
  name: string;
  slug: string;
  city: string | null;
  isActive: boolean;
  deliveryPrice: number;
  freeDeliveryMinQuantity: number | null;
  deliveryEstimationMinutes: number | null;
  userCount: number;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class MarketsService {
  private readonly logger = new Logger(MarketsService.name);
  private readonly isProduction: boolean;

  constructor(private drizzle: DrizzleService) {
    this.isProduction = process.env.NODE_ENV === 'production';
  }

  /**
   * Get all active markets with pagination, search, and filters
   */
  async findAll(params: MarketQueryParams = {}) {
    const {
      page = 1,
      limit = 50,
      search,
      city,
      sortBy = 'name',
      sortOrder = 'asc',
    } = params;

    // ✅ Validate pagination
    this.validatePagination(page, limit);

    const offset = (page - 1) * limit;
    const conditions: any[] = [eq(markets.isActive, true)];

    // ✅ Apply search filter
    if (search && search.trim().length >= 2) {
      const pattern = `%${search.trim()}%`;
      conditions.push(
        or(
          like(markets.name, pattern),
          like(markets.slug, pattern),
          like(markets.city, pattern),
        ),
      );
    }

    // ✅ Apply city filter
    if (city && city.trim()) {
      conditions.push(eq(markets.city, city.trim()));
    }

    const whereClause = and(...conditions);

    // ✅ Determine sort column
    const sortColumn = this.getSortColumn(sortBy);
    const sortDirection =
      sortOrder === 'desc' ? desc(sortColumn) : asc(sortColumn);

    try {
      const [items, total] = await Promise.all([
        this.fetchMarkets(whereClause, sortDirection, limit, offset),
        this.countMarkets(whereClause),
      ]);

      const formattedItems = this.formatMarkets(items);

      // ✅ Log only in development
      if (!this.isProduction) {
        this.logger.log(
          `Retrieved ${formattedItems.length} markets (page ${page}, limit ${limit})`,
        );
      }

      return {
        items: formattedItems,
        pagination: {
          page,
          limit,
          total: total,
          totalPages: Math.ceil(total / limit),
        },
      };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to fetch markets: ${errorMessage}`);
      throw new BadRequestException('Failed to fetch markets');
    }
  }

  /**
   * Get a specific active market by ID
   */
  async findOne(id: string): Promise<MarketResponse> {
    try {
      const [market] = await this.drizzle.db
        .select({
          id: markets.id,
          name: markets.name,
          slug: markets.slug,
          city: markets.city,
          isActive: markets.isActive,
          deliveryPrice: markets.deliveryPrice,
          freeDeliveryMinQuantity: markets.freeDeliveryMinQuantity,
          deliveryEstimationMinutes: markets.deliveryEstimationMinutes,
          createdAt: markets.createdAt,
          updatedAt: markets.updatedAt,
          userCount: sql<number>`CAST(COUNT(${users.id}) AS INTEGER)`,
        })
        .from(markets)
        .leftJoin(users, eq(users.marketId, markets.id))
        .where(and(eq(markets.id, id), eq(markets.isActive, true)))
        .groupBy(
          markets.id,
          markets.name,
          markets.slug,
          markets.city,
          markets.isActive,
          markets.deliveryPrice,
          markets.freeDeliveryMinQuantity,
          markets.deliveryEstimationMinutes,
          markets.createdAt,
          markets.updatedAt,
        )
        .limit(1);

      if (!market) {
        throw new NotFoundException('Market not found');
      }

      return this.formatMarket(market);
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to fetch market ${id}: ${errorMessage}`);
      throw new BadRequestException('Failed to fetch market');
    }
  }

  /**
   * Get all markets by city
   */
  async findByCity(city: string, page: number = 1, limit: number = 50) {
    return this.findAll({ page, limit, city });
  }

  /**
   * Search markets by name, slug, or city
   */
  async search(search: string, page: number = 1, limit: number = 50) {
    if (!search || search.trim().length < 2) {
      throw new BadRequestException(
        'Search query must be at least 2 characters',
      );
    }
    return this.findAll({ page, limit, search: search.trim() });
  }

  /**
   * Get popular markets (by user count)
   */
  async findPopular(limit: number = 10) {
    return this.findAll({
      page: 1,
      limit: Math.min(limit, 20),
      sortBy: 'userCount',
      sortOrder: 'desc',
    });
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  private validatePagination(page: number, limit: number): void {
    if (page < 1 || !Number.isInteger(page)) {
      throw new BadRequestException('Page must be a positive integer');
    }

    if (limit < 1 || limit > 100 || !Number.isInteger(limit)) {
      throw new BadRequestException('Limit must be between 1 and 100');
    }
  }

  private getSortColumn(sortBy: string): any {
    switch (sortBy) {
      case 'createdAt':
        return markets.createdAt;
      case 'userCount':
        return sql`COUNT(${users.id})`;
      case 'name':
      default:
        return markets.name;
    }
  }

  private async fetchMarkets(
    whereClause: any,
    sortDirection: any,
    limit: number,
    offset: number,
  ) {
    return this.drizzle.db
      .select({
        id: markets.id,
        name: markets.name,
        slug: markets.slug,
        city: markets.city,
        isActive: markets.isActive,
        deliveryPrice: markets.deliveryPrice,
        freeDeliveryMinQuantity: markets.freeDeliveryMinQuantity,
        deliveryEstimationMinutes: markets.deliveryEstimationMinutes,
        createdAt: markets.createdAt,
        updatedAt: markets.updatedAt,
        userCount: sql<number>`CAST(COUNT(${users.id}) AS INTEGER)`,
      })
      .from(markets)
      .leftJoin(users, eq(users.marketId, markets.id))
      .where(whereClause)
      .groupBy(
        markets.id,
        markets.name,
        markets.slug,
        markets.city,
        markets.isActive,
        markets.deliveryPrice,
        markets.freeDeliveryMinQuantity,
        markets.deliveryEstimationMinutes,
        markets.createdAt,
        markets.updatedAt,
      )
      .orderBy(sortDirection)
      .limit(limit)
      .offset(offset);
  }

  private async countMarkets(whereClause: any): Promise<number> {
    const [result] = await this.drizzle.db
      .select({ count: sql<number>`COUNT(*)::int` })
      .from(markets)
      .where(whereClause);

    return Number(result?.count) || 0;
  }

  private formatMarket(market: any): MarketResponse {
    return {
      id: market.id,
      name: market.name,
      slug: market.slug,
      city: market.city,
      isActive: market.isActive ?? false,
      deliveryPrice: market.deliveryPrice ? Number(market.deliveryPrice) : 0,
      freeDeliveryMinQuantity: market.freeDeliveryMinQuantity
        ? Number(market.freeDeliveryMinQuantity)
        : null,
      deliveryEstimationMinutes: market.deliveryEstimationMinutes
        ? Number(market.deliveryEstimationMinutes)
        : null,
      userCount: Number(market.userCount) || 0,
      createdAt: market.createdAt,
      updatedAt: market.updatedAt,
    };
  }

  private formatMarkets(marketsList: any[]): MarketResponse[] {
    return marketsList.map((market) => this.formatMarket(market));
  }
}
