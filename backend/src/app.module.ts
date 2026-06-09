import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DrizzleModule } from './drizzle/drizzle.module';
import { CloudinaryModule } from './cloudinary/cloudinary.module';
import { ProductsModule } from './products/products.module';
import { CategoriesController } from './categories/categories.controller';
import { CategoriesModule } from './categories/categories.module';
import { AuthModule } from './auth/auth.module';
import { MarketsModule } from './markets/markets.module';
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DrizzleModule, // Make sure this is imported
    CloudinaryModule,
    CategoriesModule,
    ProductsModule,
    CategoriesModule,
    AuthModule,
    MarketsModule,
  ],
  controllers: [CategoriesController],
})
export class AppModule {}
