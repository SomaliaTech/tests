import { Controller, Get } from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { markets } from '../drizzle/schema';

@Controller('markets')
export class MarketsController {
  constructor(private drizzle: DrizzleService) {}

  @Get()
  async findAll() {
    return this.drizzle.db.select().from(markets);
  }
}
