import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  ParseUUIDPipe,
  Query,
  DefaultValuePipe,
  ParseIntPipe,
  BadRequestException, // ✅ ADD THIS
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiBody,
  ApiResponse,
  ApiQuery,
} from '@nestjs/swagger';
import { FaqService } from './faq.service';
import { CreateFaqDto } from './dto/create-faq.dto';
import { UpdateFaqDto } from './dto/update-faq.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@ApiTags('faq')
@Controller('faq')
export class FaqController {
  constructor(private faqService: FaqService) {}

  // ==========================================
  // PUBLIC ENDPOINTS
  // ==========================================

  @Get('active')
  @ApiOperation({
    summary: 'Get all active FAQs (Public)',
    description: 'Returns all active FAQs for the support screen',
  })
  @ApiResponse({
    status: 200,
    description: 'Active FAQs retrieved successfully',
  })
  async getActiveFaqs() {
    return this.faqService.getActiveFaqs();
  }

  @Get('categories')
  @ApiOperation({
    summary: 'Get all FAQ categories (Public)',
    description: 'Returns all unique FAQ categories with counts',
  })
  @ApiResponse({
    status: 200,
    description: 'FAQ categories retrieved successfully',
  })
  async getFaqCategories() {
    return this.faqService.getFaqCategories();
  }

  @Get('category/:category')
  @ApiOperation({
    summary: 'Get FAQs by category (Public)',
    description: 'Returns all active FAQs for a specific category',
  })
  @ApiParam({
    name: 'category',
    description: 'FAQ category name',
  })
  @ApiResponse({
    status: 200,
    description: 'FAQs by category retrieved successfully',
  })
  async getFaqsByCategory(@Param('category') category: string) {
    return this.faqService.getFaqsByCategory(category);
  }

  // ==========================================
  // ADMIN ENDPOINTS - ✅ PAGINATED
  // ==========================================

  @Get()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get all FAQs (Admin)',
    description: 'Returns all FAQs including inactive ones with pagination',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  @ApiResponse({
    status: 200,
    description: 'All FAQs retrieved successfully',
  })
  async getAllFaqs(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('search') search?: string,
    @Query('category') category?: string,
    @Query('isActive') isActive?: string,
  ) {
    const isActiveBool =
      isActive === 'true' ? true : isActive === 'false' ? false : undefined;
    return this.faqService.getAllFaqs(
      page,
      limit,
      search,
      category,
      isActiveBool,
    );
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get FAQ by ID (Admin)',
    description: 'Returns a specific FAQ',
  })
  @ApiParam({
    name: 'id',
    description: 'FAQ UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'FAQ retrieved successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'FAQ not found',
  })
  async getFaqById(@Param('id', ParseUUIDPipe) id: string) {
    return this.faqService.getFaqById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Create FAQ (Admin only)',
    description: 'Creates a new FAQ',
  })
  @ApiBody({ type: CreateFaqDto })
  @ApiResponse({
    status: 201,
    description: 'FAQ created successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid FAQ data',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Admin access required',
  })
  async createFaq(@Request() req, @Body() createFaqDto: CreateFaqDto) {
    const userId = req.user.userId || req.user.sub;
    return this.faqService.createFaq(createFaqDto, userId);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update FAQ (Admin only)',
    description: 'Updates an existing FAQ',
  })
  @ApiParam({
    name: 'id',
    description: 'FAQ UUID',
  })
  @ApiBody({ type: UpdateFaqDto })
  @ApiResponse({
    status: 200,
    description: 'FAQ updated successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'FAQ not found',
  })
  async updateFaq(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateFaqDto: UpdateFaqDto,
  ) {
    return this.faqService.updateFaq(id, updateFaqDto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Delete FAQ (Admin only)',
    description: 'Deletes an FAQ',
  })
  @ApiParam({
    name: 'id',
    description: 'FAQ UUID',
  })
  @ApiResponse({
    status: 200,
    description: 'FAQ deleted successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'FAQ not found',
  })
  async deleteFaq(@Param('id', ParseUUIDPipe) id: string) {
    return this.faqService.deleteFaq(id);
  }

  @Put(':id/toggle')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Toggle FAQ status (Admin only)',
    description: 'Activates or deactivates an FAQ',
  })
  @ApiParam({
    name: 'id',
    description: 'FAQ UUID',
  })
  @ApiResponse({
    status: 200,
    description: 'FAQ status toggled successfully',
  })
  async toggleFaqStatus(@Param('id', ParseUUIDPipe) id: string) {
    return this.faqService.toggleFaqStatus(id);
  }

  @Put('reorder')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Reorder FAQs (Admin only)',
    description: 'Updates the display order of FAQs',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        faqIds: {
          type: 'array',
          items: { type: 'string' },
          description: 'Array of FAQ IDs in desired order',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'FAQs reordered successfully',
  })
  async reorderFaqs(@Body('faqIds') faqIds: string[]) {
    if (!faqIds || !Array.isArray(faqIds) || faqIds.length === 0) {
      throw new BadRequestException('faqIds array is required');
    }
    return this.faqService.reorderFaqs(faqIds);
  }

  @Post('bulk')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Bulk create FAQs (Admin only)',
    description: 'Creates multiple FAQs at once',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        faqs: {
          type: 'array',
          items: { $ref: '#/components/schemas/CreateFaqDto' },
        },
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'FAQs created successfully',
  })
  async bulkCreateFaqs(@Request() req, @Body('faqs') faqsList: CreateFaqDto[]) {
    if (!faqsList || !Array.isArray(faqsList) || faqsList.length === 0) {
      throw new BadRequestException('faqs array is required');
    }
    const userId = req.user.userId || req.user.sub;
    return this.faqService.bulkCreateFaqs(faqsList, userId);
  }
}
