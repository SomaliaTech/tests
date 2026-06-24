// cloudflare.service.ts - Using R2 instead of Images API
import { Injectable } from '@nestjs/common';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';

@Injectable()
export class CloudflareService {
  private s3Client: S3Client;
  private bucketName: string;
  private publicUrl: string;

  constructor() {
    this.bucketName = process.env.CLOUDFLARE_R2_BUCKET_NAME!;
    this.publicUrl = process.env.CLOUDFLARE_R2_PUBLIC_URL!;

    this.s3Client = new S3Client({
      region: 'auto',
      endpoint: process.env.CLOUDFLARE_R2_ENDPOINT,
      credentials: {
        accessKeyId: process.env.CLOUDFLARE_R2_ACCESS_KEY_ID!,
        secretAccessKey: process.env.CLOUDFLARE_R2_SECRET_ACCESS_KEY!,
      },
    });
  }

  async uploadBase64(
    base64String: string,
    folder: string = 'products',
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      const base64Data = base64String.split(',')[1] || base64String;
      const buffer = Buffer.from(base64Data, 'base64');

      const timestamp = Date.now();
      const random = Math.random().toString(36).substring(7);
      const key = `${folder}/${timestamp}-${random}.jpg`;

      await this.s3Client.send(
        new PutObjectCommand({
          Bucket: this.bucketName,
          Key: key,
          Body: buffer,
          ContentType: 'image/jpeg',
          CacheControl: 'public, max-age=31536000',
        }),
      );

      return {
        secure_url: `${this.publicUrl}/${key}`,
        public_id: key,
      };
    } catch (error: any) {
      throw new Error(`Failed to upload image: ${error.message}`);
    }
  }

  async uploadFromUrl(
    imageUrl: string,
    folder: string = 'products',
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      const response = await fetch(imageUrl);
      if (!response.ok) {
        throw new Error(`Failed to fetch image: ${response.statusText}`);
      }

      const arrayBuffer = await response.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);

      const contentType = response.headers.get('content-type') || 'image/jpeg';
      const extension = contentType.split('/')[1] || 'jpg';

      const timestamp = Date.now();
      const random = Math.random().toString(36).substring(7);
      const key = `${folder}/${timestamp}-${random}.${extension}`;

      await this.s3Client.send(
        new PutObjectCommand({
          Bucket: this.bucketName,
          Key: key,
          Body: buffer,
          ContentType: contentType,
          CacheControl: 'public, max-age=31536000',
        }),
      );

      return {
        secure_url: `${this.publicUrl}/${key}`,
        public_id: key,
      };
    } catch (error: any) {
      throw new Error(`Failed to upload image from URL: ${error.message}`);
    }
  }

  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'products',
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      const timestamp = Date.now();
      const random = Math.random().toString(36).substring(7);
      const extension = file.originalname.split('.').pop() || 'jpg';
      const key = `${folder}/${timestamp}-${random}.${extension}`;

      await this.s3Client.send(
        new PutObjectCommand({
          Bucket: this.bucketName,
          Key: key,
          Body: file.buffer,
          ContentType: file.mimetype,
          CacheControl: 'public, max-age=31536000',
        }),
      );

      return {
        secure_url: `${this.publicUrl}/${key}`,
        public_id: key,
      };
    } catch (error: any) {
      throw new Error(`Failed to upload file: ${error.message}`);
    }
  }

  async deleteImage(publicId: string): Promise<any> {
    try {
      await this.s3Client.send(
        new DeleteObjectCommand({
          Bucket: this.bucketName,
          Key: publicId,
        }),
      );
      return { success: true };
    } catch (error: any) {
      throw new Error(`Failed to delete image: ${error.message}`);
    }
  }

  getImageUrl(publicId: string): string {
    return `${this.publicUrl}/${publicId}`;
  }
}
