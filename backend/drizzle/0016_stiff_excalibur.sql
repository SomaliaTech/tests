ALTER TABLE "markets" ALTER COLUMN "created_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "markets" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "markets" ALTER COLUMN "updated_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "markets" ALTER COLUMN "updated_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "markets" ADD COLUMN "delivery_price" numeric(10, 2) DEFAULT '0.00' NOT NULL;--> statement-breakpoint
ALTER TABLE "markets" ADD COLUMN "free_delivery_min_quantity" integer;--> statement-breakpoint
ALTER TABLE "markets" ADD COLUMN "delivery_estimation_minutes" integer DEFAULT 90;--> statement-breakpoint
CREATE UNIQUE INDEX "market_slug_idx" ON "markets" USING btree ("slug");--> statement-breakpoint
CREATE INDEX "market_active_idx" ON "markets" USING btree ("is_active");