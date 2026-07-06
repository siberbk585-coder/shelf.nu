-- Karofi admin seed (MySQL CLI — no Prisma). Idempotent where possible.
SET @email = 'admin@dqa-karofi.io.vn';
SET @pass = '$2b$12$hoCGodGPgWceZjOZQbqA7OfjaUM4zhy9RWYNqhCTzXsaMRiQOvm1m';
SET @uid = 'clkarofiadmin0001';
SET @oid = 'clkarofiorg00001';
SET @rid_user = 'clkarofiroleuser1';
SET @rid_admin = 'clkarofiroleadmn1';
SET @uoid = 'clkarofiuserorg01';
SET @tmid = 'clkarofiteammem01';
SET @now = NOW(3);

-- Master data
INSERT IGNORE INTO `TierLimit` (`id`, `canImportAssets`, `canExportAssets`, `canImportNRM`, `canHideShelfBranding`, `maxCustomFields`, `maxOrganizations`, `createdAt`, `updatedAt`)
VALUES
  ('free', 0, 0, 0, 0, 0, 1, @now, @now),
  ('tier_1', 1, 1, 1, 1, 1000, 1, @now, @now),
  ('tier_2', 1, 1, 1, 1, 1000, 1, @now, @now),
  ('custom', 1, 1, 1, 1, 1000, 1, @now, @now);

INSERT IGNORE INTO `Tier` (`id`, `name`, `tierLimitId`, `createdAt`, `updatedAt`)
VALUES
  ('free', 'Free', 'free', @now, @now),
  ('tier_1', 'Plus', 'tier_1', @now, @now),
  ('tier_2', 'Team', 'tier_2', @now, @now),
  ('custom', 'Custom', 'custom', @now, @now);

INSERT IGNORE INTO `Role` (`id`, `name`, `createdAt`, `updatedAt`)
VALUES
  (@rid_user, 'USER', @now, @now),
  (@rid_admin, 'ADMIN', @now, @now);

-- Admin user (org linked after Organization insert)
INSERT INTO `User` (`id`, `email`, `username`, `firstName`, `lastName`, `onboarded`, `tierId`, `createdAt`, `updatedAt`)
VALUES (@uid, @email, 'admin_clkarofi', 'Quản trị', 'viên', 1, 'free', @now, @now)
ON DUPLICATE KEY UPDATE
  `firstName` = 'Quản trị',
  `lastName` = 'viên',
  `onboarded` = 1,
  `updatedAt` = @now;

INSERT INTO `UserCredential` (`userId`, `passwordHash`, `emailVerified`, `createdAt`, `updatedAt`)
VALUES (@uid, @pass, 1, @now, @now)
ON DUPLICATE KEY UPDATE
  `passwordHash` = @pass,
  `emailVerified` = 1,
  `updatedAt` = @now;

INSERT IGNORE INTO `_RoleToUser` (`A`, `B`) VALUES (@rid_user, @uid);

INSERT INTO `Organization` (`id`, `name`, `type`, `userId`, `hasSequentialIdsMigrated`, `createdAt`, `updatedAt`)
VALUES (@oid, 'Phòng DQA', 'PERSONAL', @uid, 1, @now, @now)
ON DUPLICATE KEY UPDATE `name` = 'Phòng DQA', `updatedAt` = @now;

UPDATE `User` SET `lastSelectedOrganizationId` = @oid WHERE `id` = @uid;

INSERT INTO `UserOrganization` (`id`, `userId`, `organizationId`, `roles`, `createdAt`, `updatedAt`)
VALUES (@uoid, @uid, @oid, JSON_ARRAY('OWNER'), @now, @now)
ON DUPLICATE KEY UPDATE `roles` = JSON_ARRAY('OWNER'), `updatedAt` = @now;

INSERT INTO `TeamMember` (`id`, `name`, `organizationId`, `userId`, `createdAt`, `updatedAt`)
VALUES (@tmid, 'Quản trị viên (Owner)', @oid, @uid, @now, @now)
ON DUPLICATE KEY UPDATE `name` = 'Quản trị viên (Owner)', `updatedAt` = @now;

SELECT 'Karofi admin ready' AS status, @email AS email;
