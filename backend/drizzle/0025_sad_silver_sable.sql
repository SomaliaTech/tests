CREATE TABLE "support_settings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" varchar(255) DEFAULT 'support@farxada.com' NOT NULL,
	"phone_number" varchar(50) DEFAULT '+252615328651' NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
