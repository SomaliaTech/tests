import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { faqs } from '../drizzle/schema';
import { eq, and, asc, desc, like, or, SQL, sql, inArray } from 'drizzle-orm'; // ✅ ADD inArray
import { v4 as uuidv4 } from 'uuid';
import { CreateFaqDto } from './dto/create-faq.dto';
import { UpdateFaqDto } from './dto/update-faq.dto';
@Injectable()
export class FaqService {
  private readonly logger = new Logger(FaqService.name);

  constructor(private drizzle: DrizzleService) {}

  // ==========================================
  // PUBLIC METHODS
  // ==========================================

  /**
   * ✅ Get all active FAQs (public endpoint)
   */
  async getActiveFaqs() {
    return this.drizzle.db
      .select({
        id: faqs.id,
        question: faqs.question,
        answer: faqs.answer,
        category: faqs.category,
        order: faqs.order,
        createdAt: faqs.createdAt,
      })
      .from(faqs)
      .where(eq(faqs.isActive, true))
      .orderBy(asc(faqs.order), asc(faqs.createdAt));
  }

  /**
   * ✅ Get FAQ categories with counts
   */
  async getFaqCategories() {
    const results = await this.drizzle.db
      .select({
        category: faqs.category,
        count: sql<number>`COUNT(*)::int`,
      })
      .from(faqs)
      .where(eq(faqs.isActive, true))
      .groupBy(faqs.category)
      .orderBy(asc(faqs.category));

    return results.filter((r) => r.category !== null);
  }

  /**
   * ✅ Get FAQs by category (public endpoint)
   */
  async getFaqsByCategory(category: string) {
    if (!category || category.trim().length === 0) {
      throw new BadRequestException('Category is required');
    }

    return this.drizzle.db
      .select({
        id: faqs.id,
        question: faqs.question,
        answer: faqs.answer,
        category: faqs.category,
        order: faqs.order,
        createdAt: faqs.createdAt,
      })
      .from(faqs)
      .where(and(eq(faqs.isActive, true), eq(faqs.category, category.trim())))
      .orderBy(asc(faqs.order), asc(faqs.createdAt));
  }

  // ==========================================
  // ADMIN METHODS - ✅ PAGINATED
  // ==========================================

  /**
   * ✅ Get all FAQs with pagination (admin endpoint)
   */
  async getAllFaqs(
    page: number = 1,
    limit: number = 20,
    search?: string,
    category?: string,
    isActive?: boolean,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = [];

    if (search && search.trim()) {
      const pattern = `%${search.trim()}%`;
      conditions.push(
        or(like(faqs.question, pattern), like(faqs.answer, pattern))!,
      );
    }

    if (category) {
      conditions.push(eq(faqs.category, category));
    }

    if (isActive !== undefined) {
      conditions.push(eq(faqs.isActive, isActive));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [items, total] = await Promise.all([
      this.drizzle.db
        .select()
        .from(faqs)
        .where(whereClause)
        .orderBy(asc(faqs.order), desc(faqs.createdAt))
        .limit(limit)
        .offset(offset),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(faqs)
        .where(whereClause),
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

  /**
   * ✅ Get FAQ by ID
   */
  async getFaqById(id: string) {
    const [faq] = await this.drizzle.db
      .select()
      .from(faqs)
      .where(eq(faqs.id, id))
      .limit(1);

    if (!faq) {
      throw new NotFoundException('FAQ not found');
    }

    return faq;
  }

  /**
   * ✅ Create FAQ (admin only)
   */
  async createFaq(createFaqDto: CreateFaqDto, userId: string) {
    // Validate required fields
    if (!createFaqDto.question || !createFaqDto.answer) {
      throw new BadRequestException('Question and answer are required');
    }

    const [faq] = await this.drizzle.db
      .insert(faqs)
      .values({
        id: uuidv4(),
        question: createFaqDto.question.trim(),
        answer: createFaqDto.answer.trim(),
        category: createFaqDto.category?.trim() || null,
        order: createFaqDto.order ?? 0,
        isActive: createFaqDto.isActive ?? true,
        createdBy: userId,
      })
      .returning();

    this.logger.log(`FAQ created: ${faq.id}`);
    return faq;
  }

  /**
   * ✅ Bulk create FAQs (admin only)
   */
  async bulkCreateFaqs(faqsList: CreateFaqDto[], userId: string) {
    if (faqsList.length > 50) {
      throw new BadRequestException('Cannot create more than 50 FAQs at once');
    }

    const results: any[] = [];
    for (const faqData of faqsList) {
      const result = await this.createFaq(faqData, userId);
      results.push(result);
    }
    for (const faqData of faqsList) {
      const result = await this.createFaq(faqData, userId);
      results.push(result);
    }

    this.logger.log(`Bulk created ${results.length} FAQs`);
    return {
      message: `${results.length} FAQs created successfully`,
      faqs: results,
    };
  }

  /**
   * ✅ Update FAQ (admin only)
   */
  async updateFaq(id: string, updateFaqDto: UpdateFaqDto) {
    await this.getFaqById(id);

    const updateData: any = { updatedAt: new Date() };

    if (updateFaqDto.question !== undefined) {
      updateData.question = updateFaqDto.question.trim();
    }
    if (updateFaqDto.answer !== undefined) {
      updateData.answer = updateFaqDto.answer.trim();
    }
    if (updateFaqDto.category !== undefined) {
      updateData.category = updateFaqDto.category?.trim() || null;
    }
    if (updateFaqDto.order !== undefined) {
      updateData.order = updateFaqDto.order;
    }
    if (updateFaqDto.isActive !== undefined) {
      updateData.isActive = updateFaqDto.isActive;
    }

    const [updatedFaq] = await this.drizzle.db
      .update(faqs)
      .set(updateData)
      .where(eq(faqs.id, id))
      .returning();

    this.logger.log(`FAQ updated: ${updatedFaq.id}`);
    return updatedFaq;
  }

  /**
   * ✅ Delete FAQ (admin only)
   */
  async deleteFaq(id: string) {
    await this.getFaqById(id);
    await this.drizzle.db.delete(faqs).where(eq(faqs.id, id));

    this.logger.log(`FAQ deleted: ${id}`);
    return { message: 'FAQ deleted successfully' };
  }

  /**
   * ✅ Toggle FAQ active status
   */
  async toggleFaqStatus(id: string) {
    const faq = await this.getFaqById(id);

    const [updatedFaq] = await this.drizzle.db
      .update(faqs)
      .set({
        isActive: !faq.isActive,
        updatedAt: new Date(),
      })
      .where(eq(faqs.id, id))
      .returning();

    this.logger.log(
      `FAQ ${id} ${updatedFaq.isActive ? 'activated' : 'deactivated'}`,
    );
    return updatedFaq;
  }

  /**
   * ✅ Reorder FAQs
   */
  async reorderFaqs(faqIds: string[]) {
    // Verify all FAQs exist
    const existingFaqs = await this.drizzle.db
      .select({ id: faqs.id })
      .from(faqs)
      .where(inArray(faqs.id, faqIds));

    if (existingFaqs.length !== faqIds.length) {
      throw new BadRequestException('One or more FAQ IDs are invalid');
    }

    // Update order in a transaction
    for (let i = 0; i < faqIds.length; i++) {
      await this.drizzle.db
        .update(faqs)
        .set({ order: i, updatedAt: new Date() })
        .where(eq(faqs.id, faqIds[i]));
    }

    this.logger.log('FAQs reordered');
    return { message: 'FAQs reordered successfully' };
  }
}
