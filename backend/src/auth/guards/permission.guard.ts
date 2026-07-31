// src/auth/guards/permission.guard.ts
import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { DrizzleService } from '../../drizzle/drizzle.service';
import { roles, userRoles, users } from '../../drizzle/schema';
import { eq } from 'drizzle-orm';

export const PERMISSIONS_KEY = 'permissions';

export const Permissions = (...permissions: string[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);

@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private drizzle: DrizzleService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredPermissions = this.reflector.getAllAndOverride<string[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    // ✅ If route has no specific permission requirement, allow it
    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const userId = request.user?.userId;

    if (!userId) {
      throw new ForbiddenException('User not authenticated');
    }

    const [user] = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    // ✅ Super admin bypass
    if (user.isSuperAdmin) {
      return true;
    }

    const roleRows = await this.drizzle.db
      .select({ permissions: roles.permissions })
      .from(userRoles)
      .innerJoin(roles, eq(roles.id, userRoles.roleId))
      .where(eq(userRoles.userId, userId));

    const userPermissions = new Set<string>();

    roleRows.forEach((row) => {
      (row.permissions ?? []).forEach((permission) => {
        userPermissions.add(permission);
      });
    });

    const hasPermission = requiredPermissions.some((permission) => {
      if (userPermissions.has(permission)) {
        return true;
      }

      // ✅ Wildcard support:
      // product:manage allows product:view, product:create, etc.
      const moduleName = permission.split(':')[0];
      return userPermissions.has(`${moduleName}:manage`);
    });

    if (!hasPermission) {
      throw new ForbiddenException(
        `You do not have permission. Required: ${requiredPermissions.join(' or ')}`,
      );
    }

    return true;
  }
}
