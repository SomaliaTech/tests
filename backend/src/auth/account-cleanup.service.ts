// src/auth/account-cleanup.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { lt, and, isNotNull, eq } from 'drizzle-orm';
import { DrizzleService } from '../drizzle/drizzle.service';
import { users } from '../drizzle/schema';

@Injectable()
export class AccountCleanupService {
  private readonly logger = new Logger(AccountCleanupService.name);

  constructor(private drizzle: DrizzleService) {}

  // Runs every day at 03:00 AM server time
  @Cron('0 3 * * *')
  async purgeExpiredAccounts() {
    this.logger.log('Running expired account cleanup...');

    const now = new Date();

    try {
      const expired = await this.drizzle.db
        .select({ id: users.id, deletedAt: users.deletedAt })
        .from(users)
        .where(and(isNotNull(users.deletedAt), lt(users.deletedAt, now)));

      if (expired.length === 0) {
        this.logger.log('No expired accounts to purge.');
        return;
      }

      for (const user of expired) {
        await this.drizzle.db.delete(users).where(eq(users.id, user.id));
        this.logger.log(
          `Permanently deleted user ${user.id} (was scheduled for ${user.deletedAt})`,
        );
      }

      this.logger.log(`Purged ${expired.length} expired accounts.`);
    } catch (e) {
      this.logger.error(`Account cleanup failed: ${e}`);
    }
  }
}
