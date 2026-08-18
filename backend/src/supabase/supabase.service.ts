import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { configureSupabase } from './supabase.config';
import WebSocket from 'ws';
import * as dns from 'dns';
import * as net from 'net';
import { promisify } from 'util';

const dnsLookup = promisify(dns.lookup);
const dnsResolve4 = promisify(dns.resolve4);

@Injectable()
export class SupabaseService {
  private supabase: SupabaseClient;
  private bucketName: string;
  private readonly MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
  private readonly ALLOWED_IMAGE_TYPES = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  ];

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

  /**
   * ✅ SSRF PROTECTION: Validate URL before fetching
   */
  private async validateImageUrl(url: string): Promise<void> {
    let parsedUrl: URL;

    try {
      parsedUrl = new URL(url);
    } catch (error) {
      throw new Error('Invalid URL format');
    }

    // 1. Only allow HTTP and HTTPS
    if (parsedUrl.protocol !== 'http:' && parsedUrl.protocol !== 'https:') {
      throw new Error('Only HTTP and HTTPS URLs are allowed');
    }

    // 2. Block localhost and internal IPs
    const hostname = parsedUrl.hostname.toLowerCase();

    // Block localhost variations
    if (
      hostname === 'localhost' ||
      hostname === '127.0.0.1' ||
      hostname === '0.0.0.0' ||
      hostname === '::1' ||
      hostname === '[::1]' ||
      hostname.endsWith('.localhost') ||
      hostname.endsWith('.local') ||
      hostname.endsWith('.internal')
    ) {
      throw new Error('Localhost URLs are not allowed');
    }

    // 3. Resolve DNS and block private/internal IP ranges
    try {
      const addresses = await dnsResolve4(hostname);

      for (const address of addresses) {
        if (this.isPrivateIp(address)) {
          throw new Error(`Private IP address ${address} is not allowed`);
        }
      }
    } catch (error) {
      if (error instanceof Error && error.message.includes('not allowed')) {
        throw error;
      }
      // DNS resolution failed - check if hostname is an IP
      if (this.isPrivateIp(hostname)) {
        throw new Error('Private IP addresses are not allowed');
      }
    }

    // 4. Block cloud metadata endpoints
    if (
      hostname === '169.254.169.254' || // AWS/GCP/Azure metadata
      hostname === 'metadata.google.internal' ||
      hostname === 'metadata.google.com'
    ) {
      throw new Error('Cloud metadata endpoints are not allowed');
    }
  }

  /**
   * ✅ Check if IP is private/internal
   */
  private isPrivateIp(ip: string): boolean {
    const parts = ip.split('.').map(Number);

    if (parts.length !== 4) return false;

    const [a, b, c, d] = parts;

    // 10.0.0.0/8
    if (a === 10) return true;

    // 172.16.0.0/12
    if (a === 172 && b >= 16 && b <= 31) return true;

    // 192.168.0.0/16
    if (a === 192 && b === 168) return true;

    // 127.0.0.0/8 (loopback)
    if (a === 127) return true;

    // 169.254.0.0/16 (link-local)
    if (a === 169 && b === 254) return true;

    // 0.0.0.0/8
    if (a === 0) return true;

    return false;
  }

  /**
   * ✅ Validate content type and file size
   */
  private validateImageMetadata(
    contentType: string,
    contentLength: number,
  ): void {
    if (!this.ALLOWED_IMAGE_TYPES.includes(contentType)) {
      throw new Error(`Unsupported content type: ${contentType}`);
    }

    if (contentLength > this.MAX_FILE_SIZE) {
      throw new Error(
        `File too large: ${(contentLength / 1024 / 1024).toFixed(2)}MB`,
      );
    }
  }

  /**
   * ✅ Upload Base64 (safe - no URL fetching)
   */
  async uploadBase64(
    base64String: string,
    folder: string,
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      let base64Data = base64String;
      let contentType = 'image/jpeg'; // Default

      // Handle data URI format
      if (base64String.includes('data:')) {
        const matches = base64String.match(/^data:(image\/\w+);base64,(.+)$/);
        if (matches) {
          contentType = matches[1];
          base64Data = matches[2];
        } else {
          base64Data = base64String.split(',')[1];
        }
      }

      if (!base64Data || base64Data.length === 0) {
        throw new Error('Invalid base64 string');
      }

      // ✅ Validate content type
      if (!this.ALLOWED_IMAGE_TYPES.includes(contentType)) {
        throw new Error(`Unsupported image type: ${contentType}`);
      }

      const buffer = Buffer.from(base64Data, 'base64');

      // ✅ Validate file size
      if (buffer.length > this.MAX_FILE_SIZE) {
        throw new Error(
          `File too large: ${(buffer.length / 1024 / 1024).toFixed(2)}MB`,
        );
      }

      // Get extension from content type
      const extension = contentType.split('/')[1] || 'jpg';

      const timestamp = Date.now();
      const randomString = Math.random().toString(36).substring(2, 15);
      const fileName = `${folder}/${timestamp}-${randomString}.${extension}`;

      const { data, error } = await this.supabase.storage
        .from(this.bucketName)
        .upload(fileName, buffer, {
          contentType,
          upsert: false,
          cacheControl: '3600',
        });

      if (error) {
        throw new Error(`Supabase upload failed: ${error.message}`);
      }

      const { data: urlData } = this.supabase.storage
        .from(this.bucketName)
        .getPublicUrl(data.path);

      return {
        secure_url: urlData.publicUrl,
        public_id: data.path,
      };
    } catch (error: any) {
      console.error('Supabase upload error:', error.message);
      throw new Error(`Failed to upload base64 image: ${error.message}`);
    }
  }

  /**
   * ✅ Upload from URL (with SSRF protection)
   */
  async uploadFromUrl(
    imageUrl: string,
    folder: string = 'products',
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      console.log('Uploading image from URL:', imageUrl);

      // ✅ SSRF PROTECTION: Validate URL first
      await this.validateImageUrl(imageUrl);

      const response = await fetch(imageUrl, {
        signal: AbortSignal.timeout(10000), // 10 second timeout
        headers: {
          'User-Agent': 'Farxada-Image-Uploader/1.0',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch image: ${response.statusText}`);
      }

      const contentType = response.headers.get('content-type') || '';
      const contentLength = parseInt(
        response.headers.get('content-length') || '0',
        10,
      );

      // ✅ Validate metadata
      this.validateImageMetadata(contentType, contentLength);

      const arrayBuffer = await response.arrayBuffer();
      const fileBuffer = Buffer.from(arrayBuffer);

      // Double-check actual size
      if (fileBuffer.length > this.MAX_FILE_SIZE) {
        throw new Error(
          `File too large: ${(fileBuffer.length / 1024 / 1024).toFixed(2)}MB`,
        );
      }

      const extension = contentType.split('/')[1] || 'jpg';
      const timestamp = Date.now();
      const random = Math.random().toString(36).substring(7);
      const filePath = `${folder}/${timestamp}-${random}.${extension}`;

      const { data, error } = await this.supabase.storage
        .from(this.bucketName)
        .upload(filePath, fileBuffer, {
          contentType,
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

  /**
   * ✅ Upload multipart file
   */
  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'products',
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      // ✅ Validate file type
      if (!this.ALLOWED_IMAGE_TYPES.includes(file.mimetype)) {
        throw new Error(`Unsupported file type: ${file.mimetype}`);
      }

      // ✅ Validate file size
      if (file.size > this.MAX_FILE_SIZE) {
        throw new Error(
          `File too large: ${(file.size / 1024 / 1024).toFixed(2)}MB`,
        );
      }

      const timestamp = Date.now();
      const random = Math.random().toString(36).substring(7);
      const extension =
        file.originalname.split('.').pop()?.toLowerCase() || 'jpg';
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
      // ✅ Validate publicId to prevent path traversal
      if (publicId.includes('..') || publicId.startsWith('/')) {
        throw new Error('Invalid file path');
      }

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
