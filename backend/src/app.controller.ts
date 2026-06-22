import {
  Controller,
  Get,
  InternalServerErrorException,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiExcludeEndpoint,
} from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('Health')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  @ApiOperation({ summary: 'Check API and Database health status' })
  @ApiResponse({
    status: 200,
    description: 'System operational',
    schema: {
      example: {
        status: 'ok',
        database: 'connected',
        timestamp: '2026-01-22T10:30:00.000Z',
      },
    },
  })
  @ApiResponse({
    status: 500,
    description: 'Database or system failure',
    schema: {
      example: {
        status: 'error',
        message: 'Database connection failed',
        details: 'Connection timeout',
        timestamp: '2026-01-22T10:30:00.000Z',
      },
    },
  })
  async healthCheck() {
    try {
      const result = await this.appService.checkDatabaseHealth();
      return result;
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown database error';

      throw new InternalServerErrorException({
        status: 'error',
        message: 'Database connection failed',
        details: errorMessage,
        timestamp: new Date().toISOString(),
      });
    }
  }

  @Get()
  @ApiOperation({ summary: 'Get API information' })
  @ApiResponse({
    status: 200,
    description: 'API information retrieved',
    schema: {
      example: {
        message: 'Welcome to Ecommerce API Backend',
        version: '1.0.0',
        endpoints: {
          docs: '/api/docs',
          health: '/health',
        },
      },
    },
  })
  rootCheck() {
    return this.appService.getApiInfo();
  }

  @Get('favicon.ico')
  @ApiExcludeEndpoint()
  @HttpCode(HttpStatus.NO_CONTENT)
  getFavicon() {
    return;
  }
}
