import { Module } from '@nestjs/common';
import { ProductsController } from './products.controller';
import { ProductsService } from './products.service';
import { CloudflareModule } from 'src/cloudfare/cloudflare.module';
// DrizzleModule is already @Global(), no need to import

@Module({
  imports: [CloudflareModule],
  controllers: [ProductsController],
  providers: [ProductsService],
  exports: [ProductsService],
})
export class ProductsModule {}
