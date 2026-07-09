DROP INDEX "idx_notifications_unread";--> statement-breakpoint
DROP INDEX "idx_users_name_trgm";--> statement-breakpoint
DROP INDEX "idx_users_phone_trgm";--> statement-breakpoint
ALTER TABLE "reviews" ALTER COLUMN "created_at" SET DATA TYPE timestamp with time zone;--> statement-breakpoint
ALTER TABLE "reviews" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "reviews" ALTER COLUMN "updated_at" SET DATA TYPE timestamp with time zone;--> statement-breakpoint
ALTER TABLE "reviews" ALTER COLUMN "updated_at" SET DEFAULT now();