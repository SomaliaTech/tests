// drizzle/schema.ts
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
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

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
  },
  (table) => ({
    activeIdx: index('banner_active_idx').on(table.isActive),
    orderIdx: index('banner_order_idx').on(table.order),
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
// USERS TABLE (FIXED - REMOVED GIN INDEXES)
// ==========================================
export const users = pgTable(
  'users',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    phoneNumber: varchar('phone_number', { length: 20 }).notNull().unique(),
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
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    phoneNumberIdx: index('users_phone_number_idx').on(table.phoneNumber),
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

    // ✅ NEW FIELDS
    deliveryPrice: decimal('delivery_price', { precision: 10, scale: 2 })
      .notNull()
      .default('0.00'),
    freeDeliveryMinQuantity: integer('free_delivery_min_quantity'), // Optional: min items for free delivery
    deliveryEstimationMinutes: integer('delivery_estimation_minutes').default(
      90,
    ), // Default 90 mins

    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
  },
  (table) => ({
    slugIdx: uniqueIndex('market_slug_idx').on(table.slug),
    activeIdx: index('market_active_idx').on(table.isActive),
  }),
);

// ==========================================
// ORDERS TABLE
// ==========================================
export const orders = pgTable(
  'orders',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    orderNumber: varchar('order_number', { length: 255 }).notNull().unique(),
    customerName: varchar('customer_name', { length: 255 }).notNull(),
    customerEmail: varchar('customer_email', { length: 255 }).notNull(),
    customerPhone: varchar('customer_phone', { length: 50 }),
    shippingAddress: text('shipping_address'),
    totalAmount: decimal('total_amount', { precision: 10, scale: 2 }).notNull(),
    status: varchar('status', { length: 50 }).notNull().default('PENDING'),
    paymentStatus: varchar('payment_status', { length: 50 }).default('PENDING'),
    paymentMethod: varchar('payment_method', { length: 50 }),
    notes: text('notes'),
    userId: uuid('user_id').references(() => users.id),
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
// NOTIFICATIONS TABLE (FIXED - REMOVED PARTIAL INDEX)
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
}));

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
