// src/auth/guards/super-admin.guard.ts
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
// In super-admin.guard.ts
@Injectable()
export class SuperAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('User not authenticated');
    }

    // ✅ Strict boolean check
    if (user.isSuperAdmin !== true) {
      throw new ForbiddenException('Super Admin access required');
    }

    return true;
  }
}
