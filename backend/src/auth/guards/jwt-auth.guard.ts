// src/auth/guards/jwt-auth.guard.ts
import {
  Injectable,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    // You can add custom pre-authentication logic here if needed
    return super.canActivate(context);
  }

  handleRequest(err: any, user: any, info: any) {
    // If there's an error or no user was extracted from the token, throw 401
    if (err || !user) {
      throw (
        err ||
        new UnauthorizedException(
          'Invalid or expired token. Please log in again.',
        )
      );
    }
    return user;
  }
}
