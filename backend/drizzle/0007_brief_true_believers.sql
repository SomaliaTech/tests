ALTER TABLE "cart_items" ALTER COLUMN "product_variant_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "order_items" ALTER COLUMN "product_variant_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "order_items" ALTER COLUMN "variant_sku" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "cart_items" ADD COLUMN "product_id" uuid;--> statement-breakpoint
ALTER TABLE "order_items" ADD COLUMN "product_id" uuid;--> statement-breakpoint
CREATE INDEX "cart_product_id_idx" ON "cart_items" USING btree ("product_id");--> statement-breakpoint
CREATE INDEX "order_item_product_id_idx" ON "order_items" USING btree ("product_id");