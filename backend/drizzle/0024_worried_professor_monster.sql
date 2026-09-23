ALTER TABLE "orders" ADD COLUMN "promo_code_id" uuid;--> statement-breakpoint
ALTER TABLE "orders" ADD COLUMN "promo_code_discount" numeric(10, 2) DEFAULT '0.00';--> statement-breakpoint
ALTER TABLE "orders" ADD COLUMN "affiliate_id" uuid;--> statement-breakpoint
ALTER TABLE "orders" ADD CONSTRAINT "orders_promo_code_id_promo_codes_id_fk" FOREIGN KEY ("promo_code_id") REFERENCES "public"."promo_codes"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "orders" ADD CONSTRAINT "orders_affiliate_id_affiliates_id_fk" FOREIGN KEY ("affiliate_id") REFERENCES "public"."affiliates"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "order_promo_code_idx" ON "orders" USING btree ("promo_code_id");--> statement-breakpoint
CREATE INDEX "order_affiliate_idx" ON "orders" USING btree ("affiliate_id");