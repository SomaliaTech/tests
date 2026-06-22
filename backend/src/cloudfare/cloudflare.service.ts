import { Injectable } from '@nestjs/common';

interface CloudflareUploadResponse {
  result: {
    id: string;
    filename: string;
    uploaded: string;
    requireSignedURLs: boolean;
    variants: string[];
  };
  success: boolean;
  errors: any[];
  messages: any[];
}

@Injectable()
export class CloudflareService {
  private accountId: string;
  private apiToken: string;

  constructor() {
    this.accountId = process.env.CLOUDFLARE_ACCOUNT_ID!;
    this.apiToken = process.env.CLOUDFLARE_API_TOKEN!;
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

      const blob = await response.blob();
      const formData = new FormData();
      formData.append('file', blob, 'image.jpg');

      const url = `https://api.cloudflare.com/client/v4/accounts/${this.accountId}/images/v1`;

      const uploadResponse = await fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.apiToken}`,
        },
        body: formData,
      });

      if (!uploadResponse.ok) {
        const error = await uploadResponse.json();
        throw new Error(`Cloudflare upload failed: ${JSON.stringify(error)}`);
      }

      const result = (await uploadResponse.json()) as CloudflareUploadResponse;

      if (!result.success) {
        throw new Error(`Upload failed: ${JSON.stringify(result.errors)}`);
      }

      // Get the variant URL (public variant is usually available)
      const variantUrl =
        result.result.variants[0] || result.result.variants[1] || '';

      return {
        secure_url: variantUrl,
        public_id: result.result.id,
      };
    } catch (error: any) {
      console.error('Cloudflare upload error:', error.message);
      throw new Error(`Failed to upload image from URL: ${error.message}`);
    }
  }

  async uploadBase64(
    base64String: string,
    folder: string = 'products',
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      // Convert base64 to blob
      const base64Data = base64String.split(',')[1] || base64String;
      const buffer = Buffer.from(base64Data, 'base64');

      // ✅ FIXED: Convert buffer to Uint8Array for Blob compatibility
      const uint8Array = new Uint8Array(buffer);
      const blob = new Blob([uint8Array], { type: 'image/jpeg' });

      const formData = new FormData();
      formData.append('file', blob, 'image.jpg');

      const url = `https://api.cloudflare.com/client/v4/accounts/${this.accountId}/images/v1`;

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.apiToken}`,
        },
        body: formData,
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(`Cloudflare upload failed: ${JSON.stringify(error)}`);
      }

      const result = (await response.json()) as CloudflareUploadResponse;

      if (!result.success) {
        throw new Error(`Upload failed: ${JSON.stringify(result.errors)}`);
      }

      const variantUrl =
        result.result.variants[0] || result.result.variants[1] || '';

      return {
        secure_url: variantUrl,
        public_id: result.result.id,
      };
    } catch (error: any) {
      throw new Error(`Failed to upload base64 image: ${error.message}`);
    }
  }

  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'products',
  ): Promise<{ secure_url: string; public_id: string }> {
    try {
      // ✅ FIXED: Convert buffer to Uint8Array for Blob compatibility
      const uint8Array = new Uint8Array(file.buffer);
      const blob = new Blob([uint8Array], { type: file.mimetype });

      const formData = new FormData();
      formData.append('file', blob, file.originalname);

      const url = `https://api.cloudflare.com/client/v4/accounts/${this.accountId}/images/v1`;

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.apiToken}`,
        },
        body: formData,
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(`Cloudflare upload failed: ${JSON.stringify(error)}`);
      }

      const result = (await response.json()) as CloudflareUploadResponse;

      if (!result.success) {
        throw new Error(`Upload failed: ${JSON.stringify(result.errors)}`);
      }

      const variantUrl =
        result.result.variants[0] || result.result.variants[1] || '';

      return {
        secure_url: variantUrl,
        public_id: result.result.id,
      };
    } catch (error: any) {
      throw new Error(`Failed to upload file: ${error.message}`);
    }
  }

  async deleteImage(publicId: string): Promise<any> {
    try {
      const url = `https://api.cloudflare.com/client/v4/accounts/${this.accountId}/images/v1/${publicId}`;

      const response = await fetch(url, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${this.apiToken}`,
        },
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(`Delete failed: ${JSON.stringify(error)}`);
      }

      const result = await response.json();
      return result;
    } catch (error: any) {
      throw new Error(`Failed to delete image: ${error.message}`);
    }
  }

  getImageUrl(publicId: string): string {
    return `https://imagedelivery.net/${this.accountId}/${publicId}/public`;
  }
}
