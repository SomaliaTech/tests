import { Global, Module } from '@nestjs/common';
import { DrizzleService } from './drizzle.service';

@Global()
@Module({
  providers: [DrizzleService],
  exports: [DrizzleService], // Exporting the service exposes "this.db" to the rest of your app
})
export class DrizzleModule {}
