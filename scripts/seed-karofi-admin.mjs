#!/usr/bin/env node
/**
 * Karofi admin seeder — run on cPanel server (no tsx required).
 *
 *   cd ~/public_html/ccdc && set -a && source .env && set +a
 *   node scripts/seed-karofi-admin.mjs
 */
import { createId } from "@paralleldrive/cuid2";
import { PrismaClient } from "@prisma/client";
import { hash } from "bcryptjs";

const EMAIL = (
  process.env.KAROFI_ADMIN_EMAIL ?? "admin@dqa-karofi.io.vn"
).toLowerCase();
const PASSWORD = process.env.KAROFI_ADMIN_PASSWORD ?? "admin123";
const FIRST_NAME = process.env.KAROFI_ADMIN_FIRST_NAME ?? "Quản trị";
const LAST_NAME = process.env.KAROFI_ADMIN_LAST_NAME ?? "viên";

const db = new PrismaClient();

async function ensureMasterData() {
  for (const name of ["USER", "ADMIN"]) {
    await db.role.upsert({ where: { name }, create: { name }, update: {} });
  }
  const tiers = [
    { id: "free", name: "Free" },
    { id: "tier_1", name: "Plus" },
    { id: "tier_2", name: "Team" },
    { id: "custom", name: "Custom" },
  ];
  for (const tier of tiers) {
    await db.tier.upsert({
      where: { id: tier.id },
      create: tier,
      update: {},
    });
  }
  for (const tierId of ["free", "tier_1", "tier_2"]) {
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

async function upsertCredential(userId, password) {
  const passwordHash = await hash(password, 12);
  await db.userCredential.upsert({
    where: { userId },
    create: { userId, passwordHash, emailVerified: true },
    update: { passwordHash, emailVerified: true },
  });
}

async function ensureKarofiAdmin() {
  const existing = await db.user.findUnique({
    where: { email: EMAIL },
    select: { id: true },
  });

  if (existing) {
    await db.user.update({
      where: { id: existing.id },
      data: { onboarded: true, firstName: FIRST_NAME, lastName: LAST_NAME },
    });
    await upsertCredential(existing.id, PASSWORD);
    console.log("Karofi admin already exists — password reset.");
    return;
  }

  const userId = createId();
  const username = `${EMAIL.split("@")[0]
    .replace(/[^a-z0-9_]/gi, "_")
    .slice(0, 30)}_${userId.slice(0, 6)}`;

  await db.$transaction(async (tx) => {
    const user = await tx.user.create({
      data: {
        id: userId,
        email: EMAIL,
        username,
        firstName: FIRST_NAME,
        lastName: LAST_NAME,
        onboarded: true,
        roles: { connect: { name: "USER" } },
        organizations: {
          create: {
            name: "Phòng DQA",
            hasSequentialIdsMigrated: true,
            categories: {
              create: defaultUserCategories.map((c) => ({ ...c, userId })),
            },
            members: {
              create: {
                name: `${FIRST_NAME} ${LAST_NAME} (Owner)`,
                user: { connect: { id: userId } },
              },
            },
            assetIndexSettings: {
              create: {
                mode: "ADVANCED",
                columns: defaultFields,
                user: { connect: { id: userId } },
              },
            },
          },
        },
      },
      select: { id: true, organizations: { select: { id: true } } },
    });

    await tx.userOrganization.create({
      data: {
        userId: user.id,
        organizationId: user.organizations[0].id,
        roles: ["OWNER"],
      },
    });
  });

  await upsertCredential(userId, PASSWORD);
  console.log("Created Karofi admin with DQA workspace (OWNER).");
}

try {
  console.log(`Seeding Karofi admin: ${EMAIL}`);
  await ensureMasterData();
  await ensureKarofiAdmin();
  console.log(`\nLogin: https://ccdc.dqa-karofi.io.vn/login`);
  console.log(`Email:    ${EMAIL}`);
  console.log(`Password: ${PASSWORD}`);
} catch (err) {
  console.error(err);
  process.exit(1);
} finally {
  await db.$disconnect();
}
