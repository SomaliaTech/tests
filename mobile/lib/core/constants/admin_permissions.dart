// lib/core/constants/admin_permissions.dart
class AdminPermissions {
  static const productView = 'product:view';
  static const productCreate = 'product:create';
  static const productUpdate = 'product:update';
  static const productDelete = 'product:delete';

  static const orderView = 'order:view';
  static const userView = 'user:view';
  static const categoryView = 'category:view';
  static const marketView = 'market:view';
  static const colorView = 'color:view';
  static const sizeView = 'size:view';
  static const faqView = 'faq:view';
  static const revenueView = 'revenue:view';
  static const analyticsView = 'analytics:view';

  /// Same logic as the backend:
  /// 'product:manage' grants every 'product:*'
  static bool has(List<String> userPermissions, String required) {
    if (userPermissions.contains('*')) return true; // super admin
    if (userPermissions.contains(required)) return true;
    final module = required.split(':').first;
    return userPermissions.contains('$module:manage');
  }
}
