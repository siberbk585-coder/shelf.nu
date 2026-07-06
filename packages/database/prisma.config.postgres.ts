/**
 * Prisma config for Supabase / PostgreSQL demo & Render deploy.
 * Uses `schema.postgres.prisma` and `migrations-postgres/`.
 *
 * @see {@link file://./prisma.config.ts} — MySQL / cPanel default
 */

import path from "node:path";
import dotenv from "dotenv";
import { defineConfig } from "prisma/config";

dotenv.config({ path: path.resolve(__dirname, "../../.env"), override: false });
dotenv.config({
  path: path.resolve(__dirname, "../../.env.karofi"),
  override: true,
});

export default defineConfig({
  schema: "prisma/schema.postgres.prisma",
  migrations: {
    path: "prisma/migrations-postgres",
  },
});
