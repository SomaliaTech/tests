import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { configureSupabase } from './supabase.config';
import WebSocket from 'ws';

@Injectable()
export class SupabaseService {
  private supabase: SupabaseClient;
  private bucketName: string;

  constructor() {
    const config = configureSupabase();
    this.bucketName = config.bucketName;

    const wsConstructor = (url: string) => {
      return new WebSocket(url);
    };

    this.supabase = createClient(config.url, config.serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
      realtime: {
        params: {
          eventsPerSecond: 2,
        },
        transport: wsConstructor as any,
      },
    });
  }

  // ✅ UNIFIED: All upload methods return { secure_url, public_id }
  async uploadBase64(
    base64String: string,
    folder: string,
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      let base64Data = base64String;
      if (base64String.includes('data:')) {
        base64Data = base64String.split(',')[1];
      }

      if (!base64Data || base64Data.length === 0) {
        throw new Error('Invalid base64 string');
      }

      const buffer = Buffer.from(base64Data, 'base64');
      const timestamp = Date.now();
      const randomString = Math.random().toString(36).substring(2, 15);
      const fileName = `${folder}/${timestamp}-${randomString}.jpg`;

      const { data, error } = await this.supabase.storage
        .from(this.bucketName)
        .upload(fileName, buffer, {
          contentType: 'image/jpeg',
          upsert: false,
        });

      if (error) {
        throw new Error(`Supabase upload failed: ${error.message}`);
      }

      const { data: urlData } = this.supabase.storage
        .from(this.bucketName)
        .getPublicUrl(data.path);

      return {
        secure_url: urlData.publicUrl, // ✅ Matches expected type
        public_id: data.path, // ✅ Matches expected type
      };
    } catch (error: any) {
      console.error('Supabase upload error:', error.message);
      throw new Error(`Failed to upload base64 image: ${error.message}`);
    }
  }

  async uploadFromUrl(
    imageUrl: string,
    folder: string = 'products',
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      console.log('Uploading image from URL:', imageUrl);

      const response = await fetch(imageUrl);
      if (!response.ok) {
        throw new Error(`Failed to fetch image: ${response.statusText}`);
      }

      const arrayBuffer = await response.arrayBuffer();
      const fileBuffer = Buffer.from(arrayBuffer);

      const contentType = response.headers.get('content-type') || 'image/jpeg';
      const extension = contentType.split('/')[1] || 'jpg';

      const timestamp = Date.now();
      const random = Math.random().toString(36).substring(7);
      const filePath = `${folder}/${timestamp}-${random}.${extension}`;

      const { data, error } = await this.supabase.storage
        .from(this.bucketName)
        .upload(filePath, fileBuffer, {
          contentType: contentType,
          cacheControl: '3600',
          upsert: false,
        });

      if (error) {
        throw new Error(`Supabase upload failed: ${error.message}`);
      }

      const { data: urlData } = this.supabase.storage
        .from(this.bucketName)
        .getPublicUrl(filePath);

      return {
        secure_url: urlData.publicUrl,
        public_id: filePath,
      };
    } catch (error: any) {
      console.error('Supabase upload error:', error.message);
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
      const filePath = `${folder}/${timestamp}-${random}.${extension}`;

      const { data, error } = await this.supabase.storage
        .from(this.bucketName)
        .upload(filePath, file.buffer, {
          contentType: file.mimetype,
          cacheControl: '3600',
          upsert: false,
        });

      if (error) {
        throw new Error(`Supabase upload failed: ${error.message}`);
      }

      const { data: urlData } = this.supabase.storage
        .from(this.bucketName)
        .getPublicUrl(filePath);

      return {
        secure_url: urlData.publicUrl,
        public_id: filePath,
      };
    } catch (error: any) {
      throw new Error(`Failed to upload file: ${error.message}`);
    }
  }

  async deleteImage(publicId: string): Promise<any> {
    try {
      const { error } = await this.supabase.storage
        .from(this.bucketName)
        .remove([publicId]);

      if (error) {
        throw new Error(`Failed to delete image: ${error.message}`);
      }

      return { success: true };
    } catch (error: any) {
      throw new Error(`Failed to delete image: ${error.message}`);
    }
  }

  getImageUrl(publicId: string): string {
    const { data } = this.supabase.storage
      .from(this.bucketName)
      .getPublicUrl(publicId);
    return data.publicUrl;
  }

  async getSignedUrl(
    publicId: string,
    expiresIn: number = 3600,
  ): Promise<string> {
    const { data, error } = await this.supabase.storage
      .from(this.bucketName)
      .createSignedUrl(publicId, expiresIn);

    if (error) {
      throw new Error(`Failed to create signed URL: ${error.message}`);
    }

    return data.signedUrl;
  }
}
