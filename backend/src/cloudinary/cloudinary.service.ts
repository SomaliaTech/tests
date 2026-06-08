import { Injectable } from '@nestjs/common';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';

@Injectable()
export class CloudinaryService {
  async uploadFromUrl(
    imageUrl: string,
    folder: string = 'products',
  ): Promise<UploadApiResponse> {
    try {
      const result = await cloudinary.uploader.upload(imageUrl, {
        folder: folder,
        transformation: [{ width: 800, height: 800, crop: 'limit' }],
      });
      return result;
    } catch (error: any) {
      throw new Error(`Failed to upload image from URL: ${error}`);
    }
  }

  async uploadBase64(
    base64String: string,
    folder: string = 'products',
  ): Promise<UploadApiResponse> {
    try {
      const result = await cloudinary.uploader.upload(base64String, {
        folder: folder,
        transformation: [{ width: 800, height: 800, crop: 'limit' }],
      });
      return result;
    } catch (error: any) {
      throw new Error(`Failed to upload base64 image: ${error}`);
    }
  }

  // async deleteImage(publicId: string): Promise<any> {
  //   try {
  //     const result = await cloudinary.uploader.destroy(publicId);
  //     return result;
  //   } catch (error: any) {
  //     throw new Error(`Failed to delete image: ${error.message}`);
  //   }
  // }

  // async getImageUrl(publicId: string, transformations?: any): string {
  //   return cloudinary.url(publicId, {
  //     transformation: transformations || [
  //       { width: 800, height: 800, crop: 'limit' },
  //     ],
  //   });
  // }
}
