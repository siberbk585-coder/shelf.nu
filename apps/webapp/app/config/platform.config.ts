/**
 * Platform / hosting configuration — switches between Supabase (PostgreSQL)
 * and cPanel (MySQL + local auth + filesystem storage).
 *
 * @see {@link file://./../../docs/cpanel-setup.md}
 */

import {
  AUTH_DRIVER,
  DATABASE_PROVIDER,
  JOB_QUEUE_DRIVER,
  PLATFORM_PROFILE,
  STORAGE_DRIVER,
} from "~/utils/env";

export type DatabaseProvider = "postgresql" | "mysql";
export type AuthDriver = "supabase" | "local";
export type StorageDriver = "supabase" | "filesystem";
export type JobQueueDriver = "pgboss" | "mysql";

/**
 * `shelf` = Shelf.nu cloud / legacy shared demo.
 * `karofi` = standalone Karofi DQA (Supabase Singapore or cPanel MySQL).
 */
export type PlatformProfile = "shelf" | "karofi";

/** Resolved database provider from `DATABASE_PROVIDER` env. */
export const databaseProvider = DATABASE_PROVIDER as DatabaseProvider;

/** True when running against cPanel MySQL (not Supabase Postgres). */
export const isMysqlPlatform = databaseProvider === "mysql";

/** True when using local bcrypt auth instead of Supabase Auth. */
export const isLocalAuth = AUTH_DRIVER === "local";

/** True when storing uploads on the local filesystem. */
export const isFilesystemStorage = STORAGE_DRIVER === "filesystem";

/** True when background jobs use the MySQL `BackgroundJob` table + cron. */
export const isMysqlJobQueue = JOB_QUEUE_DRIVER === "mysql";

/** cPanel / Karofi demo stack — MySQL + local auth + filesystem + mysql jobs. */
export const isCpanelStack =
  isMysqlPlatform && isLocalAuth && isFilesystemStorage && isMysqlJobQueue;

/**
 * Deployment profile — set `PLATFORM_PROFILE=karofi` for standalone Karofi
 * (own Supabase project or cPanel). Defaults to `shelf` on Supabase cloud.
 */
export const platformProfile = (PLATFORM_PROFILE ||
  (isCpanelStack ? "karofi" : "shelf")) as PlatformProfile;

/** Standalone Karofi DQA — not the shared DQA-home demo on Seoul Supabase. */
export const isKarofiPlatform = platformProfile === "karofi";

/** Shelf.nu cloud / legacy shared demo stack. */
export const isShelfCloudPlatform = platformProfile === "shelf";
