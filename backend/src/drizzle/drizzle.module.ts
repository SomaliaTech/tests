import { Module, Global } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema';
import { DrizzleService, DRIZZLE_DB } from './drizzle.service';

@Global()
@Module({
  providers: [
    {
      provide: DRIZZLE_DB,
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const connectionString = configService.get<string>('DATABASE_URL');

        if (!connectionString) {
          throw new Error(
            'DATABASE_URL is not defined in environment variables',
          );
        }

        // Create connection pool for Supabase
        const pool = new Pool({
          connectionString,
          ssl: {
            rejectUnauthorized: false, // Required for Supabase
          },
        });

        return drizzle(pool, { schema });
      },
    },
    DrizzleService,
  ],
  exports: [DrizzleService],
})
export class DrizzleModule {}
