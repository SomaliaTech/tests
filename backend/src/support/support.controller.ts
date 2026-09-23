// src/support/support.controller.ts
import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SuperAdminGuard } from '../auth/guards/super-admin.guard';
import { SupportService } from './support.service';
import { UpdateSupportSettingsDto } from './dto/support-settings.dto';

@ApiTags('support')
@Controller()
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  // ─────────────────────────────────────────────
  // PUBLIC — anyone can read the contact info
  // ─────────────────────────────────────────────
  @Get('support/contact')
  @ApiOperation({ summary: 'Get support contact information' })
  async getPublicContact() {
    return this.supportService.getSettings();
  }

  // ─────────────────────────────────────────────
  // SUPER ADMIN — read the same settings
  // ─────────────────────────────────────────────
  @Get('admin/support/settings')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Get support settings' })
  async getAdminSettings() {
    return this.supportService.getSettings();
  }

  // ─────────────────────────────────────────────
  // SUPER ADMIN — update email and phone
  // ─────────────────────────────────────────────
  @Patch('admin/support/settings')
  @UseGuards(JwtAuthGuard, SuperAdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '👑 Super Admin: Update support email and phone' })
  @ApiBody({ type: UpdateSupportSettingsDto })
  async updateSettings(@Body() dto: UpdateSupportSettingsDto) {
    return this.supportService.updateSettings(dto);
  }
}
