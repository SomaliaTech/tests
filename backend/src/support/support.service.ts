// src/support/support.service.ts
import { Injectable } from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { supportSettings } from '../drizzle/schema';
import { eq } from 'drizzle-orm';
import { UpdateSupportSettingsDto } from './dto/support-settings.dto';

@Injectable()
export class SupportService {
  constructor(private drizzle: DrizzleService) {}

  /**
   * Get the singleton support settings row.
   * Auto-seeds defaults if none exists.
   */
  async getSettings() {
    const rows = await this.drizzle.db.select().from(supportSettings).limit(1);

    if (rows.length === 0) {
      const [created] = await this.drizzle.db
        .insert(supportSettings)
        .values({}) // defaults applied
        .returning();
      return created;
    }

    return rows[0];
  }

  /**
   * Update email and/or phone number.
   */
  async updateSettings(dto: UpdateSupportSettingsDto) {
    const updateData: Record<string, unknown> = {
      updatedAt: new Date(),
    };

    if (dto.email !== undefined) updateData.email = dto.email.trim();
    if (dto.phoneNumber !== undefined)
      updateData.phoneNumber = dto.phoneNumber.trim();

    // Upsert — insert if no row yet
    const existing = await this.drizzle.db
      .select({ id: supportSettings.id })
      .from(supportSettings)
      .limit(1);

    let updated;

    if (existing.length === 0) {
      const [created] = await this.drizzle.db
        .insert(supportSettings)
        .values(updateData as any)
        .returning();
      updated = created;
    } else {
      const [result] = await this.drizzle.db
        .update(supportSettings)
        .set(updateData)
        .where(eq(supportSettings.id, existing[0].id))
        .returning();
      updated = result;
    }

    return {
      message: 'Support settings updated successfully',
      settings: updated,
    };
  }
}
