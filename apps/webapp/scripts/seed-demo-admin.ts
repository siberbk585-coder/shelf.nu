/**
 * Demo Admin Seeder
 *
 * Creates a default Supabase auth user + Shelf.nu User with OWNER role on a
 * Personal organization, ready for email/password login on a demo environment.
 *
 * Usage:
 *   dotenv -e ../../.env.demo -- tsx scripts/seed-demo-admin.ts
 *   pnpm --filter @shelf/webapp seed:demo-admin:demo
 *
 * Override defaults:
 *   DEMO_ADMIN_EMAIL=you@example.com DEMO_ADMIN_PASSWORD='YourPass123!' pnpm ...
 */

import { AssetIndexMode, OrganizationRoles, Roles } from "@prisma/client";
import { createDatabaseClient } from "@shelf/database/client";
import { createClient } from "@supabase/supabase-js";

const EMAIL = (
  process.env.DEMO_ADMIN_EMAIL ??
  process.env.ADMIN_EMAIL ??
  "admin@demo.shelf.nu"
).toLowerCase();
const PASSWORD = process.env.DEMO_ADMIN_PASSWORD ?? "ShelfDemo123!";
const FIRST_NAME = process.env.DEMO_ADMIN_FIRST_NAME ?? "Quản trị";
const LAST_NAME = process.env.DEMO_ADMIN_LAST_NAME ?? "viên";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE) {
  console.error(
    "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE in environment."
  );
  process.exit(1);
}

const db = createDatabaseClient();
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE, {
  auth: { autoRefreshToken: false, persistSession: false },
});

/** Inserts Role/Tier master data required for user creation (idempotent). */
async function ensureMasterData(): Promise<void> {
  for (const name of [Roles.USER, Roles.ADMIN] as const) {
    await db.role.upsert({
      where: { name },
      create: { name },
      update: {},
    });
  }

  const tiers = [
    { id: "free", name: "Free" },
    { id: "tier_1", name: "Plus" },
    { id: "tier_2", name: "Team" },
    { id: "custom", name: "Custom" },
  ] as const;

  for (const tier of tiers) {
    await db.tier.upsert({
      where: { id: tier.id },
      create: { id: tier.id, name: tier.name },
      update: {},
    });
  }

  for (const tierId of ["free", "tier_1", "tier_2"] as const) {
    await db.tierLimit.upsert({
      where: { id: tierId },
      create: {
        id: tierId,
        canImportAssets: tierId !== "free",
        canExportAssets: tierId !== "free",
        canImportNRM: tierId !== "free",
        canHideShelfBranding: tierId !== "free",
        maxCustomFields: tierId === "free" ? 0 : 1000,
        maxOrganizations: 1,
      },
      update: {},
    });
    await db.tier.update({
      where: { id: tierId },
      data: { tierLimitId: tierId },
    });
  }
}

/** Default asset index columns for new personal orgs (matches onboarding). */
const defaultFields = [
  { name: "id", visible: true, position: 0 },
  { name: "status", visible: true, position: 1 },
  { name: "description", visible: true, position: 2 },
  { name: "valuation", visible: true, position: 3 },
  { name: "createdAt", visible: true, position: 4 },
  { name: "category", visible: true, position: 5 },
  { name: "tags", visible: true, position: 6 },
  { name: "location", visible: true, position: 7 },
  { name: "kit", visible: true, position: 8 },
  { name: "custody", visible: true, position: 9 },
];

const defaultUserCategories = [
  {
    name: "Thiết bị văn phòng",
    description: "Đồ dùng văn phòng",
    color: "#ab339f",
  },
  { name: "Dây cáp", description: "Dây và cáp điện", color: "#0dec5d" },
  { name: "Máy móc", description: "Thiết bị máy móc", color: "#efa578" },
  { name: "Hàng tồn kho", description: "Vật tư tồn kho", color: "#376dd8" },
];

/**
 * Ensures a confirmed Supabase auth account exists for the demo admin email.
 * When a Shelf User already exists (e.g. after region migration), creates auth
 * with the same UUID so login sessions match migrated data.
 *
 * @returns Auth user id (must match Shelf User id)
 */
async function ensureAuthUser(): Promise<string> {
  const shelfUser = await db.user.findUnique({
    where: { email: EMAIL },
    select: { id: true },
  });

  const { data: listData, error: listError } =
    await supabase.auth.admin.listUsers({ page: 1, perPage: 1000 });

  if (listError) {
    throw new Error(`Failed to list auth users: ${listError.message}`);
  }

  const existingAuth = listData.users.find(
    (u) => u.email?.toLowerCase() === EMAIL
  );

  if (existingAuth) {
    if (shelfUser && existingAuth.id !== shelfUser.id) {
      throw new Error(
        `Auth user id (${existingAuth.id}) does not match Shelf User id (${shelfUser.id}). ` +
          "Delete the auth user in Supabase Dashboard and re-run seed."
      );
    }

    const { error: updateError } = await supabase.auth.admin.updateUserById(
      existingAuth.id,
      { password: PASSWORD, email_confirm: true }
    );
    if (updateError) {
      throw new Error(`Failed to update auth user: ${updateError.message}`);
    }
    return existingAuth.id;
  }

  const createPayload = {
    email: EMAIL,
    password: PASSWORD,
    email_confirm: true,
    user_metadata: { first_name: FIRST_NAME, last_name: LAST_NAME },
    ...(shelfUser ? { id: shelfUser.id } : {}),
  };

  const { data, error } = await supabase.auth.admin.createUser(createPayload);

  if (error || !data.user) {
    throw new Error(
      `Failed to create auth user: ${error?.message ?? "no user"}`
    );
  }

  if (shelfUser && data.user.id !== shelfUser.id) {
    throw new Error(
      `Created auth id (${data.user.id}) does not match Shelf User id (${shelfUser.id}).`
    );
  }

  return data.user.id;
}

/**
 * Creates or updates the Shelf User, personal org, and OWNER association.
 */
async function ensureShelfUser(userId: string): Promise<void> {
  const existing = await db.user.findUnique({
    where: { email: EMAIL },
    select: { id: true, onboarded: true },
  });

  if (existing) {
    await db.user.update({
      where: { id: existing.id },
      data: {
        onboarded: true,
        firstName: FIRST_NAME,
        lastName: LAST_NAME,
      },
    });
    console.log(
      "Shelf user already exists — updated profile and password via Supabase."
    );
    return;
  }

  const username = EMAIL.split("@")[0]
    .replace(/[^a-z0-9_]/gi, "_")
    .slice(0, 30);

  await db.$transaction(async (tx) => {
    const user = await tx.user.create({
      data: {
        id: userId,
        email: EMAIL,
        username: `${username}_${userId.slice(0, 6)}`,
        firstName: FIRST_NAME,
        lastName: LAST_NAME,
        onboarded: true,
        roles: { connect: { name: Roles.USER } },
        organizations: {
          create: {
            name: "Phòng DQA",
            hasSequentialIdsMigrated: true,
            categories: {
              create: defaultUserCategories.map((c) => ({
                ...c,
                userId,
              })),
            },
            members: {
              create: {
                name: `${FIRST_NAME} ${LAST_NAME} (Owner)`,
                user: { connect: { id: userId } },
              },
            },
            assetIndexSettings: {
              create: {
                mode: AssetIndexMode.ADVANCED,
                columns: defaultFields,
                user: { connect: { id: userId } },
              },
            },
          },
        },
      },
      select: {
        id: true,
        organizations: { select: { id: true } },
      },
    });

    await tx.userOrganization.create({
      data: {
        userId: user.id,
        organizationId: user.organizations[0].id,
        roles: [OrganizationRoles.OWNER],
      },
    });
  });

  console.log("Created Shelf user with Personal org (OWNER role).");
}

async function main(): Promise<void> {
  console.log(`Seeding demo admin: ${EMAIL}`);
  await ensureMasterData();
  const userId = await ensureAuthUser();
  await ensureShelfUser(userId);
  console.log("\nDemo admin ready:");
  console.log(`  Email:    ${EMAIL}`);
  console.log(`  Password: ${PASSWORD}`);
  console.log("  Login:    http://localhost:3000/login");
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(async () => {
    await db.$disconnect();
  });
