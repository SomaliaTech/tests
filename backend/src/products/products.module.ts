import { Module } from '@nestjs/common';
import { ProductsController } from './products.controller';
import { ProductsService } from './products.service';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
// DrizzleModule is already @Global(), no need to import

@Module({
  imports: [CloudinaryModule],
  controllers: [ProductsController],
  providers: [ProductsService],
  exports: [ProductsService],
})
export class ProductsModule {}
