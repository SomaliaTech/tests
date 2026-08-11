ALTER TABLE "users" ALTER COLUMN "phone_number" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "has_discount" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "discount_percentage" numeric(5, 2);--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "discount_amount" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "discount_code" varchar(50);--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "discount_start_date" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "discount_end_date" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "is_flash_sale" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "flash_sale_start_time" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "flash_sale_end_time" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "flash_sale_quantity" integer;--> statement-breakpoint
ALTER TABLE "banners" ADD COLUMN "flash_sale_price" numeric(10, 2);--> statement-breakpoint
CREATE INDEX "banner_discount_idx" ON "banners" USING btree ("has_discount","is_active");--> statement-breakpoint
CREATE INDEX "banner_flash_sale_idx" ON "banners" USING btree ("is_flash_sale","is_active");--> statement-breakpoint
CREATE INDEX "banner_discount_date_idx" ON "banners" USING btree ("discount_start_date","discount_end_date");--> statement-breakpoint
CREATE INDEX "banner_flash_sale_time_idx" ON "banners" USING btree ("flash_sale_start_time","flash_sale_end_time");--> statement-breakpoint
CREATE INDEX "users_email_idx" ON "users" USING btree ("email");