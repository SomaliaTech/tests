// src/auth/guards/admin.guard.ts
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';

@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('User not authenticated');
    }

    // ✅ Strict boolean check - allows both Admins and Super Admins
    if (user.isAdmin !== true && user.isSuperAdmin !== true) {
      throw new ForbiddenException('Admin access required');
    }

    return true;
  }
}
