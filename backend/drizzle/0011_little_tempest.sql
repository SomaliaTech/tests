CREATE INDEX "idx_users_admin" ON "users" USING btree ("is_admin");--> statement-breakpoint
CREATE INDEX "idx_users_online" ON "users" USING btree ("is_online");