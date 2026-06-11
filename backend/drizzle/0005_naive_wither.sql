ALTER TABLE "users" ADD COLUMN "market_id" uuid;--> statement-breakpoint
CREATE INDEX "users_market_id_idx" ON "users" USING btree ("market_id");