CREATE TABLE "messages" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"sender_id" uuid NOT NULL,
	"receiver_id" uuid NOT NULL,
	"content" text,
	"type" varchar(50) DEFAULT 'text',
	"media_url" varchar(500),
	"is_read" boolean DEFAULT false,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "is_online" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "last_seen" timestamp;--> statement-breakpoint
ALTER TABLE "messages" ADD CONSTRAINT "messages_sender_id_users_id_fk" FOREIGN KEY ("sender_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "messages" ADD CONSTRAINT "messages_receiver_id_users_id_fk" FOREIGN KEY ("receiver_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "msg_sender_idx" ON "messages" USING btree ("sender_id");--> statement-breakpoint
CREATE INDEX "msg_receiver_idx" ON "messages" USING btree ("receiver_id");--> statement-breakpoint
CREATE INDEX "msg_created_idx" ON "messages" USING btree ("created_at");