import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { DrizzleService } from '../drizzle/drizzle.service';
import { markets } from '../drizzle/schema';

@ApiTags('markets')
@Controller('markets')
export class MarketsController {
  constructor(private drizzle: DrizzleService) {}

  @Get()
  @ApiOperation({
    summary: 'Get all markets',
    description: 'Returns a list of all available markets.',
  })
  @ApiResponse({
    status: 200,
    description: 'Markets retrieved successfully',
    schema: {
      example: [
        {
          id: '550e8400-e29b-41d4-a716-446655440000',
          name: 'Bakara Market',
          description: 'Main market in Mogadishu',
          location: 'Mogadishu, Somalia',
          createdAt: '2024-01-01T00:00:00.000Z',
        },
      ],
    },
  })
  async findAll() {
    return this.drizzle.db.select().from(markets);
  }
}
