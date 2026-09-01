// src/markets/markets.controller.ts
import {
  Controller,
  Get,
  Query,
  Param,
  DefaultValuePipe,
  ParseIntPipe,
  ParseUUIDPipe,
  BadRequestException,
  UseGuards,
  Logger,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiQuery,
  ApiParam,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { MarketsService } from './markets.service';
import { LogSanitizer } from '../common/utils/log-sanitizer.util';

@ApiTags('markets')
@Controller('markets')
@UseGuards(ThrottlerGuard) // ✅ Rate limiting for all market endpoints
export class MarketsController {
  private readonly logger = new Logger(MarketsController.name);
  private readonly isProduction: boolean;

  constructor(private readonly marketsService: MarketsService) {
    this.isProduction = process.env.NODE_ENV === 'production';
  }

  // ==========================================
  // GET ALL MARKETS
  // ==========================================
  @Get()
  @Throttle({ default: { limit: 30, ttl: 60000 } }) // ✅ 30 requests per minute
  @ApiOperation({
    summary: 'Get all active markets with delivery info',
    description:
      'Returns a paginated list of all active markets with delivery pricing, user counts, and optional search/filter capabilities.',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'Page number (default: 1)',
    example: 1,
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Items per page (default: 50, max: 100)',
    example: 50,
  })
  @ApiQuery({
    name: 'search',
    required: false,
    type: String,
    description: 'Search by name, slug, or city',
    example: 'bakara',
  })
  @ApiQuery({
    name: 'city',
    required: false,
    type: String,
    description: 'Filter by city name',
    example: 'Mogadishu',
  })
  @ApiQuery({
    name: 'sortBy',
    required: false,
    enum: ['name', 'createdAt', 'userCount'],
    description: 'Sort field (default: name)',
  })
  @ApiQuery({
    name: 'sortOrder',
    required: false,
    enum: ['asc', 'desc'],
    description: 'Sort direction (default: asc)',
  })
  @ApiResponse({
    status: 200,
    description: 'Markets retrieved successfully',
    schema: {
      example: {
        items: [
          {
            id: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Bakara Market',
            slug: 'bakara-market',
            city: 'Mogadishu',
            isActive: true,
            deliveryPrice: 10.0,
            freeDeliveryMinQuantity: 5,
            deliveryEstimationMinutes: 90,
            userCount: 150,
            createdAt: '2024-01-01T00:00:00.000Z',
            updatedAt: '2024-01-01T00:00:00.000Z',
          },
        ],
        pagination: {
          page: 1,
          limit: 50,
          total: 1,
          totalPages: 1,
        },
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Invalid query parameters' })
  @ApiResponse({ status: 429, description: 'Too many requests' })
  async findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
    @Query('search') search?: string,
    @Query('city') city?: string,
    @Query('sortBy') sortBy?: 'name' | 'createdAt' | 'userCount',
    @Query('sortOrder') sortOrder?: 'asc' | 'desc',
  ) {
    // ✅ Safe logging
    if (!this.isProduction) {
      this.logger.log('Fetching markets', {
        page,
        limit,
        search: search ? LogSanitizer.sanitizeString(search) : undefined,
        city: city ? LogSanitizer.sanitizeString(city) : undefined,
        sortBy,
        sortOrder,
      });
    }

    return this.marketsService.findAll({
      page,
      limit,
      search,
      city,
      sortBy,
      sortOrder,
    });
  }

  // ==========================================
  // GET POPULAR MARKETS
  // ==========================================
  @Get('popular')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({
    summary: 'Get popular markets (by user count)',
    description: 'Returns top markets sorted by number of users',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Number of markets to return (default: 10, max: 20)',
    example: 10,
  })
  @ApiResponse({
    status: 200,
    description: 'Popular markets retrieved successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid limit parameter' })
  async findPopular(
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number = 10,
  ) {
    if (limit < 1 || limit > 20) {
      throw new BadRequestException('Limit must be between 1 and 20');
    }

    return this.marketsService.findPopular(limit);
  }

  // ==========================================
  // SEARCH MARKETS
  // ==========================================
  @Get('search')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({
    summary: 'Search markets',
    description: 'Search markets by name, slug, or city',
  })
  @ApiQuery({
    name: 'q',
    required: true,
    type: String,
    description: 'Search query (min 2 characters)',
    example: 'bakara',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'Page number (default: 1)',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Items per page (default: 50)',
  })
  @ApiResponse({
    status: 200,
    description: 'Search results retrieved successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid search query' })
  async search(
    @Query('q') query: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
  ) {
    if (!query || query.trim().length < 2) {
      throw new BadRequestException(
        'Search query must be at least 2 characters',
      );
    }

    return this.marketsService.search(query, page, limit);
  }

  // ==========================================
  // GET MARKET BY CITY
  // ==========================================
  @Get('city/:city')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({
    summary: 'Get markets by city',
    description: 'Returns all active markets in a specific city',
  })
  @ApiParam({
    name: 'city',
    description: 'City name',
    example: 'Mogadishu',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'Page number (default: 1)',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Items per page (default: 50)',
  })
  @ApiResponse({
    status: 200,
    description: 'Markets by city retrieved successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid city parameter' })
  async findByCity(
    @Param('city') city: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
  ) {
    if (!city || city.trim().length < 2) {
      throw new BadRequestException('City name must be at least 2 characters');
    }

    return this.marketsService.findByCity(city.trim(), page, limit);
  }

  // ==========================================
  // GET MARKET BY ID
  // ==========================================
  @Get(':id')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({
    summary: 'Get a specific market by ID',
    description: 'Returns detailed information about a specific active market',
  })
  @ApiParam({
    name: 'id',
    description: 'Market UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Market retrieved successfully',
    schema: {
      example: {
        id: '550e8400-e29b-41d4-a716-446655440000',
        name: 'Bakara Market',
        slug: 'bakara-market',
        city: 'Mogadishu',
        isActive: true,
        deliveryPrice: 10.0,
        freeDeliveryMinQuantity: 5,
        deliveryEstimationMinutes: 90,
        userCount: 150,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      },
    },
  })
  @ApiResponse({ status: 404, description: 'Market not found' })
  @ApiResponse({ status: 400, description: 'Invalid market ID' })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.marketsService.findOne(id);
  }
}
