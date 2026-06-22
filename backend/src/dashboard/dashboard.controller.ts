import { Controller, Get, UseGuards, Query } from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
} from '@nestjs/swagger';
import { DashboardService } from './dashboard.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('dashboard')
@Controller('dashboard')
@UseGuards(JwtAuthGuard, AdminGuard)
@ApiBearerAuth('JWT-auth')
export class DashboardController {
  constructor(private dashboardService: DashboardService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Get dashboard statistics' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['day', 'week', 'month', 'year'],
  })
  async getStats(@Query('period') period: string = 'week') {
    return this.dashboardService.getDashboardStats(period);
  }

  @Get('users-chart')
  @ApiOperation({ summary: 'Get users chart data' })
  async getUsersChartData(@Query('period') period: string = 'week') {
    return this.dashboardService.getUsersChartData(period);
  }

  @Get('device-traffic')
  @ApiOperation({ summary: 'Get device traffic distribution' })
  async getDeviceTraffic() {
    return this.dashboardService.getDeviceTraffic();
  }

  @Get('location-traffic')
  @ApiOperation({ summary: 'Get location traffic distribution' })
  async getLocationTraffic() {
    return this.dashboardService.getLocationTraffic();
  }

  @Get('product-traffic')
  @ApiOperation({ summary: 'Get product traffic data' })
  async getProductTraffic(@Query('period') period: string = 'week') {
    return this.dashboardService.getProductTraffic(period);
  }

  @Get('recent-orders')
  @ApiOperation({ summary: 'Get recent orders' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getRecentOrders(@Query('limit') limit: number = 5) {
    return this.dashboardService.getRecentOrders(limit);
  }

  @Get('revenue-chart')
  @ApiOperation({ summary: 'Get revenue chart data' })
  async getRevenueChart(@Query('period') period: string = 'week') {
    return this.dashboardService.getRevenueChart(period);
  }
}
