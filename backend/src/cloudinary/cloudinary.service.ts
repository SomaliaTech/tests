import { Injectable } from '@nestjs/common';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';

@Injectable()
export class CloudinaryService {
  /**
   * Upload an image from a URL to Cloudinary
   * @param imageUrl - The URL of the image to upload
   * @param folder - The folder to store the image in (default: 'products')
   * @returns Cloudinary upload response
   */
  async uploadFromUrl(
    imageUrl: string,
    folder: string = 'products',
  ): Promise<UploadApiResponse> {
    try {
      console.log('Uploading image from URL:', imageUrl);
      const result = await cloudinary.uploader.upload(imageUrl, {
        folder: folder,
        transformation: [{ width: 800, height: 800, crop: 'limit' }],
      });
      console.log('Upload successful:', result.public_id);
      return result;
    } catch (error: any) {
      console.error('Cloudinary upload error:', error.message);
      throw new Error(`Failed to upload image from URL: ${error.message}`);
    }
  }

  /**
   * Upload a Base64 encoded image to Cloudinary
   * @param base64String - The Base64 encoded image string
   * @param folder - The folder to store the image in (default: 'products')
   * @returns Cloudinary upload response
   */
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
      throw new Error(`Failed to upload base64 image: ${error.message}`);
    }
  }

  /**
   * Delete an image from Cloudinary
   * @param publicId - The public ID of the image to delete
   * @returns Cloudinary deletion response
   */
  async deleteImage(publicId: string): Promise<any> {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return result;
    } catch (error: any) {
      throw new Error(`Failed to delete image: ${error.message}`);
    }
  }

  /**
   * Get the URL of an image from Cloudinary
   * @param publicId - The public ID of the image
   * @param transformations - Optional transformation parameters
   * @returns The image URL
   */
  getImageUrl(publicId: string, transformations?: any): string {
    return cloudinary.url(publicId, {
      transformation: transformations || [
        { width: 800, height: 800, crop: 'limit' },
      ],
    });
  }
}
