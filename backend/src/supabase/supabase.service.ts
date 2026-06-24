import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { configureSupabase } from './supabase.config';
import WebSocket from 'ws'; // ✅ Import ws

@Injectable()
export class SupabaseService {
  private supabase: SupabaseClient;
  private bucketName: string;

  constructor() {
    const config = configureSupabase();
    this.bucketName = config.bucketName;

    // ✅ Create a custom WebSocket constructor wrapper
    const wsConstructor = (url: string) => {
      return new WebSocket(url);
    };

    this.supabase = createClient(config.url, config.serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
      // ✅ Use the wrapper
      realtime: {
        params: {
          eventsPerSecond: 2,
        },
        transport: wsConstructor as any, // Type assertion to bypass strict typing
      },
    });
  }
  async uploadBase64(
    base64String: string,
    folder: string = 'products',
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      // Extract base64 data
      const matches = base64String.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
      if (!matches || matches.length !== 3) {
        throw new Error('Invalid base64 string');
      }

      const contentType = matches[1];
      const base64Data = matches[2];
      const fileBuffer = Buffer.from(base64Data, 'base64');

      // Generate unique filename
      const timestamp = Date.now();
      const random = Math.random().toString(36).substring(7);
      const extension = contentType.split('/')[1] || 'jpg';
      const filePath = `${folder}/${timestamp}-${random}.${extension}`;

      // Upload to Supabase Storage
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

      // Get public URL
      const { data: urlData } = this.supabase.storage
        .from(this.bucketName)
        .getPublicUrl(filePath);

      return {
        secure_url: urlData.publicUrl,
        public_id: filePath,
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

      // Fetch the image from URL
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

      // Upload to Supabase Storage
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

      // Get public URL
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

  // ✅ Helper to generate signed URL for private files
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
