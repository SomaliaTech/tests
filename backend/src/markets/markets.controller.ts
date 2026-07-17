import {
  Controller,
  Get,
  Query,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { DrizzleService } from '../drizzle/drizzle.service';
import { markets, users } from '../drizzle/schema';
import { sql, eq } from 'drizzle-orm';

@ApiTags('markets')
@Controller('markets')
export class MarketsController {
  constructor(private drizzle: DrizzleService) {}

  @Get()
  @ApiOperation({
    summary: 'Get all active markets with delivery info',
    description: 'Returns a list of all active markets with delivery pricing.',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({
    status: 200,
    description: 'Markets retrieved successfully',
    schema: {
      example: [
        {
          id: '550e8400-e29b-41d4-a716-446655440000',
          name: 'Bakara Market',
          slug: 'bakara-market',
          city: 'Mogadishu',
          isActive: true,
          deliveryPrice: '10.00',
          freeDeliveryMinQuantity: 5,
          deliveryEstimationMinutes: 90,
          userCount: 150,
          createdAt: '2024-01-01T00:00:00.000Z',
          updatedAt: '2024-01-01T00:00:00.000Z',
        },
      ],
    },
  })
  async findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
  ) {
    const offset = (page - 1) * limit;

    const [items, total] = await Promise.all([
      this.drizzle.db
        .select({
          id: markets.id,
          name: markets.name,
          slug: markets.slug,
          city: markets.city,
          isActive: markets.isActive,
          deliveryPrice: markets.deliveryPrice, // ✅ Include delivery fields
          freeDeliveryMinQuantity: markets.freeDeliveryMinQuantity,
          deliveryEstimationMinutes: markets.deliveryEstimationMinutes,
          createdAt: markets.createdAt,
          updatedAt: markets.updatedAt,
          userCount: sql<number>`CAST(COUNT(${users.id}) AS INTEGER)`,
        })
        .from(markets)
        .leftJoin(users, eq(users.marketId, markets.id))
        .where(eq(markets.isActive, true)) // ✅ Only return active markets
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
        .orderBy(markets.name)
        .limit(limit)
        .offset(offset),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(markets)
        .where(eq(markets.isActive, true)),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        total: total[0]?.count || 0,
        totalPages: Math.ceil((total[0]?.count || 0) / limit),
      },
    };
  }
}
