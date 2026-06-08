import {
  pgTable,
  uuid,
  varchar,
  text,
  decimal,
  integer,
  boolean,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

// MediaAsset Table
export const mediaAssets = pgTable(
  'media_assets',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    url: varchar('url', { length: 500 }).notNull(),
    publicId: varchar('public_id', { length: 255 }).notNull().unique(),
    productId: uuid('product_id'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
  },
  (table) => ({
    productIdx: index('product_idx').on(table.productId),
  }),
);

// Category Table
export const categories = pgTable('categories', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 255 }).notNull().unique(),
  slug: varchar('slug', { length: 255 }).notNull().unique(),
  description: text('description'),
  iconId: uuid('icon_id').unique(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Product Table
export const products = pgTable(
  'products',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    name: varchar('name', { length: 255 }).notNull(),
    slug: varchar('slug', { length: 255 }).unique(),
    description: text('description'),
    price: decimal('price', { precision: 10, scale: 2 }).notNull(),
    stock: integer('stock').notNull().default(0),
    isActive: boolean('is_active').notNull().default(true),
    categoryId: uuid('category_id').notNull(),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
  },
  (table) => ({
    categoryIdx: index('category_idx').on(table.categoryId),
    activeIdx: index('active_idx').on(table.isActive),
    slugIdx: index('slug_idx').on(table.slug),
  }),
);

// Color Table
export const colors = pgTable('colors', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 100 }).notNull().unique(),
  code: varchar('code', { length: 50 }).notNull().unique(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Size Table
export const sizes = pgTable('sizes', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 100 }).notNull().unique(),
  value: varchar('value', { length: 50 }).notNull().unique(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Product Variant Table
export const productVariants = pgTable(
  'product_variants',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    productId: uuid('product_id').notNull(),
    colorId: uuid('color_id').notNull(),
    sizeId: uuid('size_id').notNull(),
    sku: varchar('sku', { length: 255 }).notNull().unique(),
    stock: integer('stock').notNull().default(0),
    price: decimal('price', { precision: 10, scale: 2 }),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
  },
  (table) => ({
    productColorSizeUnique: index('product_color_size_unique').on(
      table.productId,
      table.colorId,
      table.sizeId,
    ),
    productIdx: index('variant_product_idx').on(table.productId),
    colorIdx: index('variant_color_idx').on(table.colorId),
    sizeIdx: index('variant_size_idx').on(table.sizeId),
    skuIdx: index('variant_sku_idx').on(table.sku),
  }),
);

// Order Table
export const orders = pgTable(
  'orders',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    orderNumber: varchar('order_number', { length: 255 }).notNull().unique(),
    customerName: varchar('customer_name', { length: 255 }).notNull(),
    customerEmail: varchar('customer_email', { length: 255 }).notNull(),
    totalAmount: decimal('total_amount', { precision: 10, scale: 2 }).notNull(),
    status: varchar('status', { length: 50 }).notNull().default('PENDING'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
  },
  (table) => ({
    statusIdx: index('order_status_idx').on(table.status),
    emailIdx: index('order_email_idx').on(table.customerEmail),
  }),
);

// Order Item Table
export const orderItems = pgTable(
  'order_items',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    orderId: uuid('order_id').notNull(),
    productVariantId: uuid('product_variant_id').notNull(),
    productName: varchar('product_name', { length: 255 }).notNull(),
    variantSku: varchar('variant_sku', { length: 255 }).notNull(),
    colorName: varchar('color_name', { length: 100 }).notNull(),
    sizeName: varchar('size_name', { length: 100 }).notNull(),
    unitPrice: decimal('unit_price', { precision: 10, scale: 2 }).notNull(),
    quantity: integer('quantity').notNull(),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => ({
    orderIdx: index('order_item_order_idx').on(table.orderId),
    variantIdx: index('order_item_variant_idx').on(table.productVariantId),
  }),
);

// Define Relations
export const mediaAssetsRelations = relations(mediaAssets, ({ one }) => ({
  product: one(products, {
    fields: [mediaAssets.productId],
    references: [products.id],
  }),
  category: one(categories, {
    fields: [mediaAssets.productId],
    references: [categories.id],
  }),
}));

export const categoriesRelations = relations(categories, ({ many, one }) => ({
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
}));

export const colorsRelations = relations(colors, ({ many }) => ({
  variants: many(productVariants),
}));

export const sizesRelations = relations(sizes, ({ many }) => ({
  variants: many(productVariants),
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
  }),
);

export const ordersRelations = relations(orders, ({ many }) => ({
  items: many(orderItems),
}));

export const orderItemsRelations = relations(orderItems, ({ one }) => ({
  order: one(orders, {
    fields: [orderItems.orderId],
    references: [orders.id],
  }),
  variant: one(productVariants, {
    fields: [orderItems.productVariantId],
    references: [productVariants.id],
  }),
}));
