// src/admin/guards/permission.guard.ts
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminService } from 'src/admin/admin.service';
import { Permission } from 'src/admin/enums/permissions.enum';

@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private adminService: AdminService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredPermissions = this.reflector.get<Permission[]>(
      'permissions',
      context.getHandler(),
    );

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('User not authenticated');
    }

    // Super Admin has all permissions
    if (user.isSuperAdmin) {
      return true;
    }

    // Check if user has required permissions
    const userPermissions = await this.adminService.getUserPermissions(
      user.userId,
    );

    const hasAllPermissions = requiredPermissions.every((permission) =>
      userPermissions.includes(permission),
    );

    if (!hasAllPermissions) {
      throw new ForbiddenException('Insufficient permissions');
    }

    return true;
  }
}

// Custom decorator for permissions
export const Permissions = (...permissions: Permission[]) =>
  Reflect.defineMetadata('permissions', permissions, Object);
