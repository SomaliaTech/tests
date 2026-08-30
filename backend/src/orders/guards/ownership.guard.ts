// src/orders/guards/ownership.guard.ts
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { DrizzleService } from '../../drizzle/drizzle.service';
import { orders, cartItems, addresses, users } from '../../drizzle/schema';
import { eq } from 'drizzle-orm';

@Injectable()
export class OwnershipGuard implements CanActivate {
  constructor(
    private drizzle: DrizzleService,
    private reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userId = request.user?.userId;
    const resourceId =
      request.params?.id || request.params?.itemId || request.params?.addressId;

    // Get resource type from metadata
    const resourceType = this.reflector.get<string>(
      'resourceType',
      context.getHandler(),
    );

    if (!userId || !resourceId || !resourceType) {
      throw new ForbiddenException('Access denied');
    }

    // Check if user is admin
    const [user] = await this.drizzle.db
      .select({
        isAdmin: users.isAdmin,
        isSuperAdmin: users.isSuperAdmin,
      })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (user?.isAdmin || user?.isSuperAdmin) {
      return true;
    }

    // Check ownership based on resource type
    let ownerId: string | null | undefined; // ✅ Changed to accept null

    switch (resourceType) {
      case 'cart':
        const [cartItem] = await this.drizzle.db
          .select({ userId: cartItems.userId })
          .from(cartItems)
          .where(eq(cartItems.id, resourceId))
          .limit(1);
        ownerId = cartItem?.userId ?? null; // ✅ Explicitly handle null
        break;

      case 'address':
        const [address] = await this.drizzle.db
          .select({ userId: addresses.userId })
          .from(addresses)
          .where(eq(addresses.id, resourceId))
          .limit(1);
        ownerId = address?.userId ?? null; // ✅ Explicitly handle null
        break;

      case 'order':
        const [order] = await this.drizzle.db
          .select({ userId: orders.userId })
          .from(orders)
          .where(eq(orders.id, resourceId))
          .limit(1);
        ownerId = order?.userId ?? null; // ✅ Explicitly handle null
        break;
    }

    if (!ownerId) {
      throw new NotFoundException(`${resourceType} not found`);
    }

    if (ownerId !== userId) {
      throw new ForbiddenException(`You do not own this ${resourceType}`);
    }

    return true;
  }
}
