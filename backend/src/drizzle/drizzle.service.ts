import { Injectable, Inject } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import * as schema from './schema';

export const DRIZZLE_DB = 'DRIZZLE_DB';

@Injectable()
export class DrizzleService {
  constructor(
    @Inject(DRIZZLE_DB) public readonly db: NodePgDatabase<typeof schema>,
  ) {}
}
