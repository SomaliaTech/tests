DROP INDEX "product_idx";--> statement-breakpoint
DROP INDEX "product_color_size_unique";--> statement-breakpoint
DROP INDEX "category_idx";--> statement-breakpoint
DROP INDEX "active_idx";--> statement-breakpoint
DROP INDEX "order_item_order_idx";--> statement-breakpoint
DROP INDEX "order_item_variant_idx";--> statement-breakpoint
DROP INDEX "order_status_idx";--> statement-breakpoint
DROP INDEX "order_email_idx";--> statement-breakpoint
DROP INDEX "variant_product_idx";--> statement-breakpoint
DROP INDEX "variant_color_idx";--> statement-breakpoint
DROP INDEX "variant_size_idx";--> statement-breakpoint
DROP INDEX "variant_sku_idx";--> statement-breakpoint
ALTER TABLE "order_items" ALTER COLUMN "color_name" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "order_items" ALTER COLUMN "size_name" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "product_variants" ALTER COLUMN "color_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "product_variants" ALTER COLUMN "size_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "categories" ADD COLUMN "parent_id" uuid;--> statement-breakpoint
ALTER TABLE "media_assets" ADD COLUMN "is_main" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "media_assets" ADD COLUMN "alt_text" varchar(255);--> statement-breakpoint
ALTER TABLE "media_assets" ADD COLUMN "order" integer DEFAULT 0;--> statement-breakpoint
ALTER TABLE "order_items" ADD COLUMN "total_price" numeric(10, 2) NOT NULL;--> statement-breakpoint
ALTER TABLE "orders" ADD COLUMN "customer_phone" varchar(50);--> statement-breakpoint
ALTER TABLE "orders" ADD COLUMN "shipping_address" text;--> statement-breakpoint
ALTER TABLE "orders" ADD COLUMN "payment_status" varchar(50) DEFAULT 'PENDING';--> statement-breakpoint
ALTER TABLE "orders" ADD COLUMN "payment_method" varchar(50);--> statement-breakpoint
ALTER TABLE "orders" ADD COLUMN "notes" text;--> statement-breakpoint
ALTER TABLE "product_variants" ADD COLUMN "compare_at_price" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "product_variants" ADD COLUMN "image_id" uuid;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "compare_at_price" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "cost_per_item" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "sku" varchar(255);--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "barcode" varchar(255);--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "weight" numeric(8, 2);--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "is_featured" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "brand" varchar(255);--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "tags" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "seo_title" varchar(255);--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "seo_description" text;--> statement-breakpoint
CREATE INDEX "category_parent_idx" ON "categories" USING btree ("parent_id");--> statement-breakpoint
CREATE INDEX "media_product_idx" ON "media_assets" USING btree ("product_id");--> statement-breakpoint
CREATE INDEX "order_number_idx" ON "orders" USING btree ("order_number");--> statement-breakpoint
CREATE INDEX "variant_product_color_size_idx" ON "product_variants" USING btree ("product_id","color_id","size_id");--> statement-breakpoint
CREATE INDEX "products_category_idx" ON "products" USING btree ("category_id");--> statement-breakpoint
CREATE INDEX "products_active_idx" ON "products" USING btree ("is_active");--> statement-breakpoint
CREATE INDEX "products_featured_idx" ON "products" USING btree ("is_featured");--> statement-breakpoint
CREATE INDEX "products_slug_idx" ON "products" USING btree ("slug");--> statement-breakpoint
CREATE INDEX "products_sku_idx" ON "products" USING btree ("sku");--> statement-breakpoint
CREATE INDEX "products_brand_idx" ON "products" USING btree ("brand");--> statement-breakpoint
CREATE INDEX "order_item_order_idx" ON "order_items" USING btree ("order_id");--> statement-breakpoint
CREATE INDEX "order_item_variant_idx" ON "order_items" USING btree ("product_variant_id");--> statement-breakpoint
CREATE INDEX "order_status_idx" ON "orders" USING btree ("status");--> statement-breakpoint
CREATE INDEX "order_email_idx" ON "orders" USING btree ("customer_email");--> statement-breakpoint
CREATE INDEX "variant_product_idx" ON "product_variants" USING btree ("product_id");--> statement-breakpoint
CREATE INDEX "variant_color_idx" ON "product_variants" USING btree ("color_id");--> statement-breakpoint
CREATE INDEX "variant_size_idx" ON "product_variants" USING btree ("size_id");--> statement-breakpoint
CREATE INDEX "variant_sku_idx" ON "product_variants" USING btree ("sku");--> statement-breakpoint
ALTER TABLE "products" ADD CONSTRAINT "products_sku_unique" UNIQUE("sku");