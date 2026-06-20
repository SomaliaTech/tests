import { Controller, Get, InternalServerErrorException } from '@nestjs/common';
import { DrizzleService } from './drizzle/drizzle.service';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { sql } from 'drizzle-orm';

@ApiTags('health') // Organizes it cleanly in your Swagger UI docs
@Controller()
export class AppController {
  constructor(private readonly drizzle: DrizzleService) {}

  @Get('health')
  @ApiOperation({ summary: 'Check API and Database status' })
  @ApiResponse({ status: 200, description: 'System operational' })
  @ApiResponse({ status: 500, description: 'Database or system failure' })
  async healthCheck() {
    try {
      // Test the database availability
      await this.drizzle.db.execute(sql`SELECT 1`);

      return {
        status: 'ok',
        database: 'connected',
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      // Throw a clean HTTP 500 error instead of a 200 containing error details
      throw new InternalServerErrorException({
        status: 'error',
        message: 'Database connection failed',
        details: error.message,
        timestamp: new Date().toISOString(),
      });
    }
  }

  // Fallback root endpoint
  @Get('/')
  rootCheck() {
    return {
      message: 'Welcome to Haldoor Ecommerce API Backend',
      docs: '/docs',
      health: '/health',
    };
  }
}
