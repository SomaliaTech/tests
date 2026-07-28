// src/admin/enums/permissions.enum.ts
export enum Permission {
  // Product Permissions
  PRODUCT_CREATE = 'product:create',
  PRODUCT_UPDATE = 'product:update',
  PRODUCT_DELETE = 'product:delete',
  PRODUCT_VIEW = 'product:view',
  PRODUCT_MANAGE = 'product:manage', // All product permissions

  // Order Permissions
  ORDER_VIEW = 'order:view',
  ORDER_UPDATE = 'order:update',
  ORDER_DELETE = 'order:delete',
  ORDER_MANAGE = 'order:manage',

  // User Permissions
  USER_VIEW = 'user:view',
  USER_CREATE = 'user:create',
  USER_UPDATE = 'user:update',
  USER_DELETE = 'user:delete',
  USER_MANAGE = 'user:manage',

  // Category Permissions
  CATEGORY_CREATE = 'category:create',
  CATEGORY_UPDATE = 'category:update',
  CATEGORY_DELETE = 'category:delete',
  CATEGORY_VIEW = 'category:view',
  CATEGORY_MANAGE = 'category:manage',

  // Market Permissions
  MARKET_CREATE = 'market:create',
  MARKET_UPDATE = 'market:update',
  MARKET_DELETE = 'market:delete',
  MARKET_VIEW = 'market:view',
  MARKET_MANAGE = 'market:manage',

  // Color Permissions
  COLOR_CREATE = 'color:create',
  COLOR_UPDATE = 'color:update',
  COLOR_DELETE = 'color:delete',
  COLOR_VIEW = 'color:view',
  COLOR_MANAGE = 'color:manage',

  // Size Permissions
  SIZE_CREATE = 'size:create',
  SIZE_UPDATE = 'size:update',
  SIZE_DELETE = 'size:delete',
  SIZE_VIEW = 'size:view',
  SIZE_MANAGE = 'size:manage',

  // FAQ Permissions
  FAQ_CREATE = 'faq:create',
  FAQ_UPDATE = 'faq:update',
  FAQ_DELETE = 'faq:delete',
  FAQ_VIEW = 'faq:view',
  FAQ_MANAGE = 'faq:manage',

  // Revenue/Financial Permissions
  REVENUE_VIEW = 'revenue:view',
  REVENUE_EXPORT = 'revenue:export',
  REVENUE_MANAGE = 'revenue:manage',

  // Analytics Permissions
  ANALYTICS_VIEW = 'analytics:view',
  ANALYTICS_EXPORT = 'analytics:export',
  ANALYTICS_MANAGE = 'analytics:manage',

  // Admin Management (Super Admin only)
  ADMIN_MANAGE = 'admin:manage',
  ADMIN_CREATE = 'admin:create',
  ADMIN_DELETE = 'admin:delete',
  ADMIN_UPDATE = 'admin:update',
  ADMIN_VIEW = 'admin:view',

  // System Permissions
  SYSTEM_SETTINGS = 'system:settings',
  SYSTEM_LOGS = 'system:logs',
}

// Permission Groups for easier assignment
export const PermissionGroups = {
  // Full access to everything (Super Admin only)
  SUPER_ADMIN: Object.values(Permission),

  // Product Manager
  PRODUCT_MANAGER: [
    Permission.PRODUCT_CREATE,
    Permission.PRODUCT_UPDATE,
    Permission.PRODUCT_DELETE,
    Permission.PRODUCT_VIEW,
    Permission.CATEGORY_VIEW,
    Permission.CATEGORY_CREATE,
    Permission.CATEGORY_UPDATE,
    Permission.CATEGORY_DELETE,
  ],

  // Order Manager
  ORDER_MANAGER: [
    Permission.ORDER_VIEW,
    Permission.ORDER_UPDATE,
    Permission.REVENUE_VIEW,
    Permission.ANALYTICS_VIEW,
  ],

  // Content Manager (FAQs, Banners)
  CONTENT_MANAGER: [
    Permission.FAQ_CREATE,
    Permission.FAQ_UPDATE,
    Permission.FAQ_DELETE,
    Permission.FAQ_VIEW,
  ],

  // Inventory Manager
  INVENTORY_MANAGER: [
    Permission.PRODUCT_VIEW,
    Permission.PRODUCT_UPDATE,
    Permission.COLOR_VIEW,
    Permission.COLOR_CREATE,
    Permission.COLOR_UPDATE,
    Permission.SIZE_VIEW,
    Permission.SIZE_CREATE,
    Permission.SIZE_UPDATE,
  ],

  // Support Manager
  SUPPORT_MANAGER: [
    Permission.USER_VIEW,
    Permission.ORDER_VIEW,
    Permission.FAQ_VIEW,
    Permission.FAQ_CREATE,
    Permission.FAQ_UPDATE,
  ],

  // View Only
  VIEW_ONLY: [
    Permission.PRODUCT_VIEW,
    Permission.ORDER_VIEW,
    Permission.USER_VIEW,
    Permission.CATEGORY_VIEW,
    Permission.MARKET_VIEW,
    Permission.REVENUE_VIEW,
    Permission.ANALYTICS_VIEW,
  ],
};
