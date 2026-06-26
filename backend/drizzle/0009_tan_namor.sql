CREATE TABLE "conversations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"participant1" uuid NOT NULL,
	"participant2" uuid NOT NULL,
	"last_message" text,
	"last_message_type" varchar(20) DEFAULT 'text',
	"last_message_at" timestamp DEFAULT now(),
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
DROP INDEX "msg_sender_idx";--> statement-breakpoint
DROP INDEX "msg_receiver_idx";--> statement-breakpoint
DROP INDEX "msg_created_idx";--> statement-breakpoint
ALTER TABLE "messages" ALTER COLUMN "type" SET DATA TYPE varchar(20);--> statement-breakpoint
ALTER TABLE "messages" ALTER COLUMN "type" SET DEFAULT 'text';--> statement-breakpoint
ALTER TABLE "messages" ALTER COLUMN "type" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "messages" ALTER COLUMN "media_url" SET DATA TYPE text;--> statement-breakpoint
ALTER TABLE "messages" ALTER COLUMN "created_at" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "messages" ADD COLUMN "conversation_id" uuid NOT NULL;--> statement-breakpoint
ALTER TABLE "messages" ADD COLUMN "read_at" timestamp;--> statement-breakpoint
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_participant1_users_id_fk" FOREIGN KEY ("participant1") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_participant2_users_id_fk" FOREIGN KEY ("participant2") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "unique_conversation_participants" ON "conversations" USING btree ("participant1","participant2");--> statement-breakpoint
CREATE INDEX "idx_conversation_p1" ON "conversations" USING btree ("participant1");--> statement-breakpoint
CREATE INDEX "idx_conversation_p2" ON "conversations" USING btree ("participant2");--> statement-breakpoint
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversation_id_conversations_id_fk" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_messages_conversation" ON "messages" USING btree ("conversation_id","created_at" DESC NULLS LAST);--> statement-breakpoint
CREATE INDEX "idx_messages_sender" ON "messages" USING btree ("sender_id");--> statement-breakpoint
CREATE INDEX "idx_messages_receiver" ON "messages" USING btree ("receiver_id");--> statement-breakpoint
CREATE INDEX "idx_messages_unread" ON "messages" USING btree ("receiver_id","is_read");