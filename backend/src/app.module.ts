import { Module } from '@nestjs/common';
import { CloudinaryModule } from './cloudinary/cloudinary.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProductsModule } from './products/product.module';
import { configureCloudinary } from './cloudinary/cloudinary.provider';

configureCloudinary();
@Module({
  imports: [PrismaModule, CloudinaryModule, ProductsModule],
})
export class AppModule {}
