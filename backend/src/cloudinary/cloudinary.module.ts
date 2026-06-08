import { Module, Global } from '@nestjs/common';
import { CloudinaryService } from './cloudinary.service';
import { configureCloudinary } from './cloudinary.config';

@Global()
@Module({
  providers: [CloudinaryService],
  exports: [CloudinaryService],
})
export class CloudinaryModule {
  constructor() {
    configureCloudinary();
  }
}
