// src/drizzle/schema.ts

import {
  decimal,
  integer,
  pgTable,
  uuid,
  varchar,
  timestamp,
  boolean,
  text,
  index,
  uniqueIndex,
  jsonb,
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { numeric } from 'drizzle-orm/pg-core';

// ==========================================
// CATEGORY TABLE
// ==========================================
export const categories = pgTable(
  'categories',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    name: varchar('name', { length: 255 }).notNull(),
    slug: varchar('slug', { length: 255 }).notNull().unique(),
    description: text('description'),
    iconId: uuid('icon_id').unique(),
    parentId: uuid('parent_id'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    parentIdx: index('category_parent_idx').on(table.parentId),
    slugIdx: index('category_slug_idx').on(table.slug),
    nameIdx: index('category_name_idx').on(table.name),
    activeIdx: index('category_active_idx').on(table.isActive),
  }),
);

// ==========================================
// BANNERS TABLE
// ==========================================
export const banners = pgTable(
  'banners',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    title: varchar('title', { length: 255 }).notNull(),
    subtitle: varchar('subtitle', { length: 500 }),
    imageUrl: varchar('image_url', { length: 500 }).notNull(),
    buttonText: varchar('button_text', { length: 100 }),
    actionLink: varchar('action_link', { length: 500 }),
    backgroundColor: varchar('background_color', { length: 50 }),
    gradientStart: varchar('gradient_start', { length: 50 }),
    gradientEnd: varchar('gradient_end', { length: 50 }),
    isActive: boolean('is_active').default(true),
    order: integer('order').default(0),
    createdBy: uuid('created_by').references(() => users.id),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    hasDiscount: boolean('has_discount').default(false).notNull(),
    discountPercentage: decimal('discount_percentage', {
      precision: 5,
      scale: 2,
    }),
    discountAmount: decimal('discount_amount', {
      precision: 10,
      scale: 2,
    }),
    discountCode: varchar('discount_code', { length: 50 }),
    discountStartDate: timestamp('discount_start_date', {
      withTimezone: true,
    }),
    discountEndDate: timestamp('discount_end_date', {
      withTimezone: true,
    }),
    isFlashSale: boolean('is_flash_sale').default(false).notNull(),
    flashSaleStartTime: timestamp('flash_sale_start_time', {
      withTimezone: true,
    }),
    flashSaleEndTime: timestamp('flash_sale_end_time', {
      withTimezone: true,
    }),
    flashSaleQuantity: integer('flash_sale_quantity'),
    flashSalePrice: decimal('flash_sale_price', {
      precision: 10,
      scale: 2,
    }),
  },
  (table) => ({
    activeIdx: index('banner_active_idx').on(table.isActive),
    orderIdx: index('banner_order_idx').on(table.order),
    discountIdx: index('banner_discount_idx').on(
      table.hasDiscount,
      table.isActive,
    ),
    flashSaleIdx: index('banner_flash_sale_idx').on(
      table.isFlashSale,
      table.isActive,
    ),
    discountDateIdx: index('banner_discount_date_idx').on(
      table.discountStartDate,
      table.discountEndDate,
    ),
    flashSaleTimeIdx: index('banner_flash_sale_time_idx').on(
      table.flashSaleStartTime,
      table.flashSaleEndTime,
    ),
  }),
);

// ==========================================
// FAQ TABLE
// ==========================================
export const faqs = pgTable(
  'faqs',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    question: varchar('question', { length: 500 }).notNull(),
    answer: text('answer').notNull(),
    category: varchar('category', { length: 100 }),
    order: integer('order').default(0),
    isActive: boolean('is_active').default(true),
    createdBy: uuid('created_by').references(() => users.id),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    activeIdx: index('faq_active_idx').on(table.isActive),
    orderIdx: index('faq_order_idx').on(table.order),
  }),
);

// ==========================================
// PRODUCT TABLE
// ==========================================
export const products = pgTable(
  'products',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    name: varchar('name', { length: 255 }).notNull(),
    slug: varchar('slug', { length: 255 }).unique(),
    description: text('description'),
    price: decimal('price', { precision: 10, scale: 2 }).notNull(),
    compareAtPrice: decimal('compare_at_price', { precision: 10, scale: 2 }),
    costPerItem: decimal('cost_per_item', { precision: 10, scale: 2 }),
    stock: integer('stock').notNull().default(0),
    sku: varchar('sku', { length: 255 }).unique(),
    barcode: varchar('barcode', { length: 255 }),
    weight: decimal('weight', { precision: 8, scale: 2 }),
    isActive: boolean('is_active').notNull().default(true),
    isFeatured: boolean('is_featured').default(false),
    categoryId: uuid('category_id').notNull(),
    brand: varchar('brand', { length: 255 }),
    tags: text('tags'),
    seoTitle: varchar('seo_title', { length: 255 }),
    seoDescription: text('seo_description'),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    categoryIdx: index('products_category_idx').on(table.categoryId),
    activeIdx: index('products_active_idx').on(table.isActive),
    featuredIdx: index('products_featured_idx').on(table.isFeatured),
    slugIdx: index('products_slug_idx').on(table.slug),
    skuIdx: index('products_sku_idx').on(table.sku),
    brandIdx: index('products_brand_idx').on(table.brand),
  }),
);

// ==========================================
// MEDIA ASSETS TABLE
// ==========================================
export const mediaAssets = pgTable(
  'media_assets',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    url: varchar('url', { length: 500 }).notNull(),
    publicId: varchar('public_id', { length: 255 }).notNull().unique(),
    productId: uuid('product_id'),
    isMain: boolean('is_main').default(false),
    altText: varchar('alt_text', { length: 255 }),
    order: integer('order').default(0),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    productIdx: index('media_product_idx').on(table.productId),
  }),
);

// ==========================================
// COLORS TABLE
// ==========================================
export const colors = pgTable('colors', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 100 }).notNull().unique(),
  code: varchar('code', { length: 50 }).notNull().unique(),
  createdAt: timestamp('created_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
});

// ==========================================
// SIZES TABLE
// ==========================================
export const sizes = pgTable('sizes', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 100 }).notNull().unique(),
  value: varchar('value', { length: 50 }).notNull().unique(),
  createdAt: timestamp('created_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
});

// ==========================================
// PRODUCT VARIANTS TABLE
// ==========================================
export const productVariants = pgTable(
  'product_variants',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    productId: uuid('product_id')
      .notNull()
      .references(() => products.id, { onDelete: 'cascade' }),
    colorId: uuid('color_id').references(() => colors.id),
    sizeId: uuid('size_id').references(() => sizes.id),
    sku: varchar('sku', { length: 100 }),
    stock: integer('stock').notNull().default(0),
    price: decimal('price', { precision: 10, scale: 2 }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow(),
  },
  (table) => ({
    productIdx: index('variant_product_idx').on(table.productId),
    colorIdx: index('variant_color_idx').on(table.colorId),
    sizeIdx: index('variant_size_idx').on(table.sizeId),
  }),
);

// ==========================================
// USERS TABLE
// ==========================================
export const users = pgTable(
  'users',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    phoneNumber: varchar('phone_number', { length: 20 }).unique(),
    email: varchar('email', { length: 255 }),
    name: varchar('name', { length: 255 }),
    profileImage: varchar('profile_image', { length: 500 }),
    marketId: uuid('market_id'),
    isVerified: boolean('is_verified').default(false),
    isAdmin: boolean('is_admin').default(false),
    isSuperAdmin: boolean('is_super_admin').default(false),
    isActive: boolean('is_active').default(true),
    isOnline: boolean('is_online').default(false),
    lastSeen: timestamp('last_seen', { withTimezone: true }),
    otpCode: varchar('otp_code', { length: 6 }),
    otpExpiresAt: timestamp('otp_expires_at', { withTimezone: true }),
    facebookId: varchar('facebook_id', { length: 255 }).unique(),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    deletedAt: timestamp('deleted_at'),
  },
  (table) => ({
    phoneNumberIdx: index('users_phone_number_idx').on(table.phoneNumber),
    emailIdx: index('users_email_idx').on(table.email),
    marketIdIdx: index('users_market_id_idx').on(table.marketId),
    adminActiveIdx: index('idx_users_admin_active').on(
      table.isAdmin,
      table.isSuperAdmin,
      table.isActive,
    ),
    onlineIdx: index('idx_users_online').on(table.isOnline),
    activeIdx: index('idx_users_active').on(table.isActive),
  }),
);

// ==========================================
// DEVICE TOKENS TABLE
// ==========================================
export const deviceTokens = pgTable(
  'device_tokens',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    token: varchar('token', { length: 500 }).notNull().unique(),
    platform: varchar('platform', { length: 20 }).notNull(),
    isActive: boolean('is_active').default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow(),
  },
  (table) => ({
    userIdIdx: index('device_tokens_user_idx').on(table.userId),
    tokenIdx: index('device_tokens_token_idx').on(table.token),
    activeIdx: index('idx_device_tokens_active').on(
      table.userId,
      table.isActive,
    ),
  }),
);

// ==========================================
// ADDRESSES TABLE
// ==========================================
export const addresses = pgTable(
  'addresses',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    label: varchar('label', { length: 50 }).notNull(),
    fullAddress: text('full_address').notNull(),
    phoneNumber: varchar('phone_number', { length: 20 }).notNull(),
    isDefault: boolean('is_default').default(false),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    userIdIdx: index('address_user_idx').on(table.userId),
  }),
);

// ==========================================
// MARKETS TABLE
// ==========================================
export const markets = pgTable(
  'markets',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    name: varchar('name', { length: 255 }).notNull(),
    slug: varchar('slug', { length: 255 }).notNull().unique(),
    city: varchar('city', { length: 255 }),
    isActive: boolean('is_active').default(true),
    deliveryPrice: decimal('delivery_price', { precision: 10, scale: 2 })
      .notNull()
      .default('0.00'),
    freeDeliveryMinQuantity: integer('free_delivery_min_quantity'),
    deliveryEstimationMinutes: integer('delivery_estimation_minutes').default(
      90,
    ),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
  },
  (table) => ({
    slugIdx: uniqueIndex('market_slug_idx').on(table.slug),
    activeIdx: index('market_active_idx').on(table.isActive),
  }),
);

// ==========================================
// ✅ ORDERS TABLE - FIXED
// ==========================================
export const orders = pgTable(
  'orders',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    orderNumber: varchar('order_number', { length: 255 }).notNull().unique(),
    userId: uuid('user_id').references(() => users.id),
    customerName: varchar('customer_name', { length: 255 }).notNull(),
    customerEmail: varchar('customer_email', { length: 255 }),
    customerPhone: varchar('customer_phone', { length: 50 }),
    shippingAddress: text('shipping_address'),
    totalAmount: decimal('total_amount', { precision: 10, scale: 2 }).notNull(),
    status: varchar('status', { length: 50 }).notNull().default('PENDING'),
    paymentMethod: varchar('payment_method', { length: 50 }),
    paymentStatus: varchar('payment_status', { length: 50 }).default('PENDING'),
    paymentReferenceId: varchar('payment_reference_id', { length: 255 }),

    // ✅ ADD THESE BACK — they exist in your DB
    promoCodeId: uuid('promo_code_id').references(() => promoCodes.id, {
      onDelete: 'set null',
    }),
    promoCodeDiscount: decimal('promo_code_discount', {
      precision: 10,
      scale: 2,
    }).default('0.00'),
    affiliateId: uuid('affiliate_id').references(() => affiliates.id, {
      onDelete: 'set null',
    }),

    completedAt: timestamp('completed_at', { withTimezone: true }),
    notes: text('notes'),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    statusIdx: index('order_status_idx').on(table.status),
    emailIdx: index('order_email_idx').on(table.customerEmail),
    orderNumberIdx: index('order_number_idx').on(table.orderNumber),
    userIdIdx: index('order_user_id_idx').on(table.userId),
    paymentStatusIdx: index('order_payment_status_idx').on(table.paymentStatus),
    paymentRefIdx: index('order_payment_ref_idx').on(table.paymentReferenceId),
    // ✅ ADD THESE INDEXES
    promoCodeIdx: index('order_promo_code_idx').on(table.promoCodeId),
    affiliateIdx: index('order_affiliate_idx').on(table.affiliateId),
  }),
);

// ==========================================
// CONVERSATIONS TABLE
// ==========================================
export const conversations = pgTable(
  'conversations',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    participant1: uuid('participant1')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    participant2: uuid('participant2')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    lastMessage: text('last_message'),
    lastMessageType: varchar('last_message_type', { length: 20 }).default(
      'text',
    ),
    lastMessageAt: timestamp('last_message_at', {
      withTimezone: true,
    }).defaultNow(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow(),
  },
  (table) => ({
    participant1Idx: index('idx_conversation_p1').on(table.participant1),
    participant2Idx: index('idx_conversation_p2').on(table.participant2),
    lastMessageIdx: index('idx_conversation_last_message').on(
      table.lastMessageAt.desc(),
    ),
    participantsIdx: index('idx_conversation_participants').on(
      table.participant1,
      table.participant2,
    ),
  }),
);

// ==========================================
// MESSAGES TABLE
// ==========================================
export const messages = pgTable(
  'messages',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    conversationId: uuid('conversation_id')
      .notNull()
      .references(() => conversations.id, { onDelete: 'cascade' }),
    senderId: uuid('sender_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    receiverId: uuid('receiver_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    content: text('content'),
    type: varchar('type', { length: 20 }).notNull().default('text'),
    mediaUrl: text('media_url'),
    isRead: boolean('is_read').default(false),
    readAt: timestamp('read_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    conversationCreatedIdx: index('idx_messages_conversation_created').on(
      table.conversationId,
      table.createdAt.desc(),
    ),
    senderIdx: index('idx_messages_sender').on(table.senderId),
    receiverIdx: index('idx_messages_receiver').on(table.receiverId),
    readStatusIdx: index('idx_messages_read_status').on(
      table.conversationId,
      table.receiverId,
      table.isRead,
    ),
    receiverReadIdx: index('idx_messages_receiver_read').on(
      table.receiverId,
      table.isRead,
    ),
  }),
);

// ==========================================
// CART ITEMS TABLE
// ==========================================
export const cartItems = pgTable(
  'cart_items',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    productId: uuid('product_id')
      .notNull()
      .references(() => products.id, { onDelete: 'cascade' }),
    productVariantId: uuid('product_variant_id').references(
      () => productVariants.id,
      { onDelete: 'cascade' },
    ),
    quantity: integer('quantity').notNull().default(1),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    userIdIdx: index('cart_user_id_idx').on(table.userId),
    productVariantIdx: index('cart_product_variant_idx').on(
      table.productVariantId,
    ),
    productIdIdx: index('cart_product_id_idx').on(table.productId),
  }),
);

// ==========================================
// ORDER ITEMS TABLE
// ==========================================
export const orderItems = pgTable(
  'order_items',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    orderId: uuid('order_id')
      .notNull()
      .references(() => orders.id, { onDelete: 'cascade' }),
    productId: uuid('product_id').references(() => products.id),
    productVariantId: uuid('product_variant_id').references(
      () => productVariants.id,
    ),
    productName: varchar('product_name', { length: 255 }).notNull(),
    variantSku: varchar('variant_sku', { length: 255 }),
    colorName: varchar('color_name', { length: 100 }),
    sizeName: varchar('size_name', { length: 100 }),
    unitPrice: decimal('unit_price', { precision: 10, scale: 2 }).notNull(),
    quantity: integer('quantity').notNull(),
    totalPrice: decimal('total_price', { precision: 10, scale: 2 }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    orderIdx: index('order_item_order_idx').on(table.orderId),
    variantIdx: index('order_item_variant_idx').on(table.productVariantId),
    productIdIdx: index('order_item_product_id_idx').on(table.productId),
  }),
);

// ==========================================
// PAYMENT TRANSACTIONS TABLE
// ==========================================
export const paymentTransactions = pgTable(
  'payment_transactions',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    orderId: uuid('order_id')
      .notNull()
      .references(() => orders.id, { onDelete: 'cascade' }),
    transactionId: varchar('transaction_id', { length: 255 }).unique(),
    amount: decimal('amount', { precision: 10, scale: 2 }).notNull(),
    paymentMethod: varchar('payment_method', { length: 50 }).notNull(),
    status: varchar('status', { length: 50 }).notNull().default('PENDING'),
    paymentDetails: text('payment_details'),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    orderIdIdx: index('payment_order_id_idx').on(table.orderId),
    statusIdx: index('payment_status_idx').on(table.status),
    transactionIdIdx: index('payment_transaction_id_idx').on(
      table.transactionId,
    ),
  }),
);

// ==========================================
// NOTIFICATIONS TABLE
// ==========================================
export const notifications = pgTable(
  'notifications',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    type: varchar('type', { length: 50 }).notNull(),
    title: varchar('title', { length: 255 }).notNull(),
    message: text('message').notNull(),
    isRead: boolean('is_read').default(false),
    actionText: varchar('action_text', { length: 100 }),
    actionLink: varchar('action_link', { length: 500 }),
    imageUrl: varchar('image_url', { length: 500 }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    userIdIdx: index('notification_user_idx').on(table.userId),
    typeIdx: index('notification_type_idx').on(table.type),
    createdAtIdx: index('notification_created_at_idx').on(table.createdAt),
  }),
);

// ==========================================
// REVIEWS TABLE
// ==========================================
export const reviews = pgTable(
  'reviews',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    productId: uuid('product_id')
      .notNull()
      .references(() => products.id, { onDelete: 'cascade' }),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    orderId: uuid('order_id')
      .notNull()
      .references(() => orders.id),
    rating: integer('rating').notNull(),
    title: varchar('title', { length: 200 }),
    comment: text('comment'),
    isVerifiedPurchase: boolean('is_verified_purchase').default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    uniqueUserProduct: uniqueIndex('review_user_product_idx').on(
      table.userId,
      table.productId,
    ),
    productIdx: index('review_product_idx').on(table.productId),
  }),
);

// ==========================================
// ROLES TABLE
// ==========================================
export const roles = pgTable(
  'roles',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    name: varchar('name', { length: 100 }).notNull(),
    description: varchar('description', { length: 500 }),
    permissions: jsonb('permissions').$type<string[]>().notNull().default([]),
    isSystem: boolean('is_system').default(false),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    nameIdx: index('idx_roles_name').on(table.name),
    systemIdx: index('idx_roles_system').on(table.isSystem),
  }),
);

// ==========================================
// USER ROLES JUNCTION TABLE
// ==========================================
export const userRoles = pgTable(
  'user_roles',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    roleId: uuid('role_id')
      .notNull()
      .references(() => roles.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    userIdIdx: index('idx_user_roles_user_id').on(table.userId),
    roleIdIdx: index('idx_user_roles_role_id').on(table.roleId),
    uniqueUserRole: uniqueIndex('idx_user_roles_unique').on(
      table.userId,
      table.roleId,
    ),
  }),
);

// ==========================================
// 🚀 RELATIONS
// ==========================================

export const categoriesRelations = relations(categories, ({ one, many }) => ({
  parent: one(categories, {
    fields: [categories.parentId],
    references: [categories.id],
    relationName: 'parentChild',
  }),
  children: many(categories, { relationName: 'parentChild' }),
  products: many(products),
  icon: one(mediaAssets, {
    fields: [categories.iconId],
    references: [mediaAssets.id],
  }),
}));

export const productsRelations = relations(products, ({ one, many }) => ({
  category: one(categories, {
    fields: [products.categoryId],
    references: [categories.id],
  }),
  images: many(mediaAssets),
  variants: many(productVariants),
  cartItems: many(cartItems),
  orderItems: many(orderItems),
  reviews: many(reviews),
}));

export const mediaAssetsRelations = relations(mediaAssets, ({ one }) => ({
  product: one(products, {
    fields: [mediaAssets.productId],
    references: [products.id],
  }),
}));

export const productVariantsRelations = relations(
  productVariants,
  ({ one, many }) => ({
    product: one(products, {
      fields: [productVariants.productId],
      references: [products.id],
    }),
    color: one(colors, {
      fields: [productVariants.colorId],
      references: [colors.id],
    }),
    size: one(sizes, {
      fields: [productVariants.sizeId],
      references: [sizes.id],
    }),
    orderItems: many(orderItems),
    cartItems: many(cartItems),
  }),
);

export const addressesRelations = relations(addresses, ({ one }) => ({
  user: one(users, {
    fields: [addresses.userId],
    references: [users.id],
  }),
}));

export const deviceTokensRelations = relations(deviceTokens, ({ one }) => ({
  user: one(users, {
    fields: [deviceTokens.userId],
    references: [users.id],
  }),
}));

export const marketsRelations = relations(markets, ({ many }) => ({
  users: many(users),
}));

export const cartItemsRelations = relations(cartItems, ({ one }) => ({
  user: one(users, {
    fields: [cartItems.userId],
    references: [users.id],
  }),
  product: one(products, {
    fields: [cartItems.productId],
    references: [products.id],
  }),
  variant: one(productVariants, {
    fields: [cartItems.productVariantId],
    references: [productVariants.id],
  }),
}));

export const ordersRelations = relations(orders, ({ one, many }) => ({
  user: one(users, {
    fields: [orders.userId],
    references: [users.id],
  }),
  items: many(orderItems),
  payment: one(paymentTransactions, {
    fields: [orders.id],
    references: [paymentTransactions.orderId],
  }),
}));

export const orderItemsRelations = relations(orderItems, ({ one }) => ({
  order: one(orders, {
    fields: [orderItems.orderId],
    references: [orders.id],
  }),
  product: one(products, {
    fields: [orderItems.productId],
    references: [products.id],
  }),
  variant: one(productVariants, {
    fields: [orderItems.productVariantId],
    references: [productVariants.id],
  }),
}));
export const paymentTransactionsRelations = relations(
  paymentTransactions,
  ({ one }) => ({
    order: one(orders, {
      fields: [paymentTransactions.orderId],
      references: [orders.id],
    }),
  }),
);

export const notificationsRelations = relations(notifications, ({ one }) => ({
  user: one(users, {
    fields: [notifications.userId],
    references: [users.id],
  }),
}));

export const conversationsRelations = relations(
  conversations,
  ({ one, many }) => ({
    participant1User: one(users, {
      fields: [conversations.participant1],
      references: [users.id],
      relationName: 'participant1',
    }),
    participant2User: one(users, {
      fields: [conversations.participant2],
      references: [users.id],
      relationName: 'participant2',
    }),
    messages: many(messages),
  }),
);

export const messagesRelations = relations(messages, ({ one }) => ({
  conversation: one(conversations, {
    fields: [messages.conversationId],
    references: [conversations.id],
  }),
  sender: one(users, {
    fields: [messages.senderId],
    references: [users.id],
    relationName: 'sender',
  }),
  receiver: one(users, {
    fields: [messages.receiverId],
    references: [users.id],
    relationName: 'receiver',
  }),
}));

export const reviewsRelations = relations(reviews, ({ one }) => ({
  product: one(products, {
    fields: [reviews.productId],
    references: [products.id],
  }),
  user: one(users, {
    fields: [reviews.userId],
    references: [users.id],
  }),
  order: one(orders, {
    fields: [reviews.orderId],
    references: [orders.id],
  }),
}));

export const rolesRelations = relations(roles, ({ many }) => ({
  userRoles: many(userRoles),
}));

export const userRolesRelations = relations(userRoles, ({ one }) => ({
  user: one(users, {
    fields: [userRoles.userId],
    references: [users.id],
  }),
  role: one(roles, {
    fields: [userRoles.roleId],
    references: [roles.id],
  }),
}));

export const usersRelations = relations(users, ({ one, many }) => ({
  market: one(markets, {
    fields: [users.marketId],
    references: [markets.id],
  }),
  addresses: many(addresses),
  orders: many(orders),
  cartItems: many(cartItems),
  notifications: many(notifications),
  deviceTokens: many(deviceTokens),
  sentMessages: many(messages, { relationName: 'sender' }),
  receivedMessages: many(messages, { relationName: 'receiver' }),
  conversationsAsP1: many(conversations, { relationName: 'participant1' }),
  conversationsAsP2: many(conversations, { relationName: 'participant2' }),
  reviews: many(reviews),
  userRoles: many(userRoles),
}));

// Add these new tables at the end of your schema.ts file

// ==========================================
// AFFILIATE REQUESTS TABLE
// ==========================================
export const affiliateRequests = pgTable('affiliate_requests', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id')
    .references(() => users.id, { onDelete: 'cascade' })
    .notNull(),
  businessName: varchar('business_name', { length: 255 }).notNull(),
  description: text('description'),
  phoneNumber: varchar('phone_number', { length: 20 }),
  socialMediaLinks: jsonb('social_media_links').$type<Record<string, string>>(),
  expectedAudience: integer('expected_audience'),
  status: varchar('status', { length: 20 }).default('PENDING').notNull(), // PENDING, APPROVED, REJECTED
  rejectionReason: text('rejection_reason'),
  reviewedBy: uuid('reviewed_by').references(() => users.id),
  appliedAt: timestamp('applied_at').defaultNow().notNull(),
  reviewedAt: timestamp('reviewed_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// ==========================================
// AFFILIATES TABLE (Approved marketers)
// ==========================================
export const affiliates = pgTable('affiliates', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id')
    .references(() => users.id, { onDelete: 'cascade' })
    .notNull()
    .unique(),
  uniqueCode: varchar('unique_code', { length: 20 }).notNull().unique(), // e.g., "FARX-INA-7X9K"
  commissionRate: numeric('commission_rate', { precision: 5, scale: 2 })
    .default('5.00')
    .notNull(), // 5% default
  totalEarnings: numeric('total_earnings', { precision: 12, scale: 2 })
    .default('0.00')
    .notNull(),
  paidEarnings: numeric('paid_earnings', { precision: 12, scale: 2 })
    .default('0.00')
    .notNull(),
  pendingEarnings: numeric('pending_earnings', { precision: 12, scale: 2 })
    .default('0.00')
    .notNull(),
  totalOrders: integer('total_orders').default(0).notNull(),
  totalCustomers: integer('total_customers').default(0).notNull(),
  status: varchar('status', { length: 20 }).default('ACTIVE').notNull(), // ACTIVE, SUSPENDED
  joinedAt: timestamp('joined_at').defaultNow().notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// ==========================================
// PROMO CODES TABLE
// ==========================================
export const promoCodes = pgTable('promo_codes', {
  id: uuid('id').primaryKey().defaultRandom(),
  code: varchar('code', { length: 50 }).notNull().unique(), // e.g., "SAVE20" or "INA2026"
  affiliateId: uuid('affiliate_id').references(() => affiliates.id, {
    onDelete: 'cascade',
  }), // null = system-wide
  description: text('description'),
  discountType: varchar('discount_type', { length: 20 }).notNull(), // PERCENTAGE, FIXED
  discountValue: numeric('discount_value', {
    precision: 10,
    scale: 2,
  }).notNull(),
  minOrderAmount: numeric('min_order_amount', { precision: 10, scale: 2 }), // Minimum order to apply
  maxDiscountAmount: numeric('max_discount_amount', {
    precision: 10,
    scale: 2,
  }), // Cap for percentage discounts
  maxUses: integer('max_uses'), // null = unlimited
  usedCount: integer('used_count').default(0).notNull(),
  maxUsesPerUser: integer('max_uses_per_user').default(1).notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  startsAt: timestamp('starts_at'),
  expiresAt: timestamp('expires_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// ==========================================
// PROMO CODE USAGE TABLE
// ==========================================
export const promoCodeUsage = pgTable('promo_code_usage', {
  id: uuid('id').primaryKey().defaultRandom(),
  promoCodeId: uuid('promo_code_id')
    .references(() => promoCodes.id, { onDelete: 'cascade' })
    .notNull(),
  userId: uuid('user_id')
    .references(() => users.id, { onDelete: 'cascade' })
    .notNull(),
  orderId: uuid('order_id').references(() => orders.id, {
    onDelete: 'set null',
  }),
  affiliateId: uuid('affiliate_id').references(() => affiliates.id, {
    onDelete: 'set null',
  }),
  orderAmount: numeric('order_amount', { precision: 12, scale: 2 }).notNull(),
  discountAmount: numeric('discount_amount', {
    precision: 10,
    scale: 2,
  }).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// ==========================================
// AFFILIATE COMMISSIONS TABLE
// ==========================================
export const affiliateCommissions = pgTable('affiliate_commissions', {
  id: uuid('id').primaryKey().defaultRandom(),
  affiliateId: uuid('affiliate_id')
    .references(() => affiliates.id, { onDelete: 'cascade' })
    .notNull(),
  orderId: uuid('order_id').references(() => orders.id, {
    onDelete: 'set null',
  }),
  promoCodeId: uuid('promo_code_id').references(() => promoCodes.id, {
    onDelete: 'set null',
  }),
  orderAmount: numeric('order_amount', { precision: 12, scale: 2 }).notNull(),
  commissionRate: numeric('commission_rate', {
    precision: 5,
    scale: 2,
  }).notNull(),
  commissionAmount: numeric('commission_amount', {
    precision: 10,
    scale: 2,
  }).notNull(),
  status: varchar('status', { length: 20 }).default('PENDING').notNull(), // PENDING, PAID, CANCELLED
  paidAt: timestamp('paid_at'),
  cancelledAt: timestamp('cancelled_at'),
  cancellationReason: text('cancellation_reason'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// ==========================================
// ADD RELATIONS
// ==========================================
// Add to your existing relations block:

export const affiliateRequestsRelations = relations(
  affiliateRequests,
  ({ one }) => ({
    user: one(users, {
      fields: [affiliateRequests.userId],
      references: [users.id],
    }),
    reviewer: one(users, {
      fields: [affiliateRequests.reviewedBy],
      references: [users.id],
    }),
  }),
);

export const affiliatesRelations = relations(affiliates, ({ one, many }) => ({
  user: one(users, { fields: [affiliates.userId], references: [users.id] }),
  promoCodes: many(promoCodes),
  commissions: many(affiliateCommissions),
}));

export const promoCodesRelations = relations(promoCodes, ({ one, many }) => ({
  affiliate: one(affiliates, {
    fields: [promoCodes.affiliateId],
    references: [affiliates.id],
  }),
  usages: many(promoCodeUsage),
}));

export const promoCodeUsageRelations = relations(promoCodeUsage, ({ one }) => ({
  promoCode: one(promoCodes, {
    fields: [promoCodeUsage.promoCodeId],
    references: [promoCodes.id],
  }),
  user: one(users, { fields: [promoCodeUsage.userId], references: [users.id] }),
  order: one(orders, {
    fields: [promoCodeUsage.orderId],
    references: [orders.id],
  }),
  affiliate: one(affiliates, {
    fields: [promoCodeUsage.affiliateId],
    references: [affiliates.id],
  }),
}));

export const affiliateCommissionsRelations = relations(
  affiliateCommissions,
  ({ one }) => ({
    affiliate: one(affiliates, {
      fields: [affiliateCommissions.affiliateId],
      references: [affiliates.id],
    }),
    order: one(orders, {
      fields: [affiliateCommissions.orderId],
      references: [orders.id],
    }),
    promoCode: one(promoCodes, {
      fields: [affiliateCommissions.promoCodeId],
      references: [promoCodes.id],
    }),
  }),
);

// ✅ Single-row settings table for the affiliate program
export const affiliateSettings = pgTable('affiliate_settings', {
  id: uuid('id').primaryKey().defaultRandom(),

  // Commission defaults
  defaultCommissionRate: decimal('default_commission_rate', {
    precision: 5,
    scale: 2,
  })
    .notNull()
    .default('5.00'),
  minPayoutAmount: decimal('min_payout_amount', { precision: 10, scale: 2 })
    .notNull()
    .default('10.00'),
  payoutCycleDays: integer('payout_cycle_days').notNull().default(30),

  // Promo code defaults
  defaultDiscountType: varchar('default_discount_type', { length: 20 })
    .notNull()
    .default('PERCENTAGE'),
  defaultDiscountValue: decimal('default_discount_value', {
    precision: 10,
    scale: 2,
  })
    .notNull()
    .default('5.00'),
  defaultMaxUsesPerUser: integer('default_max_uses_per_user')
    .notNull()
    .default(1),

  // Program rules
  requireApproval: boolean('require_approval').notNull().default(true),
  autoApprovePromoCodes: boolean('auto_approve_promo_codes')
    .notNull()
    .default(false),
  allowSelfReferral: boolean('allow_self_referral').notNull().default(false),
  cookieWindowDays: integer('cookie_window_days').notNull().default(30),

  // Notifications
  notifyOnNewApplication: boolean('notify_on_new_application')
    .notNull()
    .default(true),
  notifyOnNewCommission: boolean('notify_on_new_commission')
    .notNull()
    .default(true),
  notifyOnCodeApproval: boolean('notify_on_code_approval')
    .notNull()
    .default(true),
  emailDigest: boolean('email_digest').notNull().default(false),

  updatedAt: timestamp('updated_at').notNull().defaultNow(),
});
// ==========================================
// SUPPORT SETTINGS (single-row table)
// ==========================================
export const supportSettings = pgTable('support_settings', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: varchar('email', { length: 255 })
    .notNull()
    .default('support@farxada.com'),
  phoneNumber: varchar('phone_number', { length: 50 })
    .notNull()
    .default('+252615328651'),
  updatedAt: timestamp('updated_at', { withTimezone: true })
    .defaultNow()
    .notNull(),
});
