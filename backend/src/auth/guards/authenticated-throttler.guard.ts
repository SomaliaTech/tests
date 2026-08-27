import { Injectable, Inject, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import {
  ThrottlerGuard,
  ThrottlerStorage,
  ThrottlerRequest,
} from '@nestjs/throttler';
// ✅ Use 'import type' for ThrottlerModuleOptions to satisfy isolatedModules
import type { ThrottlerModuleOptions } from '@nestjs/throttler';
import * as jwt from 'jsonwebtoken';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthenticatedThrottlerGuard extends ThrottlerGuard {
  private readonly jwtSecret: string;

  constructor(
    @Inject('THROTTLER_OPTIONS')
    protected readonly options: ThrottlerModuleOptions,

    @Inject('THROTTLER_STORAGE')
    protected readonly storageService: ThrottlerStorage,

    protected readonly reflector: Reflector,
    private readonly configService: ConfigService,
  ) {
    // Pass arguments to super
    super(options, storageService, reflector);

    this.jwtSecret =
      this.configService.get<string>('JWT_SECRET') || 'your_default_secret';
  }

  protected async handleRequest(
    requestProps: ThrottlerRequest,
  ): Promise<boolean> {
    const { context } = requestProps;
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    // Check if the request has a Bearer token
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        // Verify the token synchronously
        jwt.verify(token, this.jwtSecret);

        // ✅ If the token is valid, the user is authenticated.
        // Return true to BYPASS the rate limit (unlimited requests).
        return true;
      } catch {
        // Token is invalid or expired, fall through to standard rate limiting
      }
    }

    // ✅ For unauthenticated users, apply the standard rate limit
    return super.handleRequest(requestProps);
  }
}
