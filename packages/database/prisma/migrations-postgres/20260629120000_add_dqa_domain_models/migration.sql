-- CreateEnum
CREATE TYPE "DqaOperationalStatus" AS ENUM ('OPERATIONAL', 'NON_OPERATIONAL', 'UNDER_CALIBRATION', 'QUARANTINED');

-- CreateEnum
CREATE TYPE "CalibrationType" AS ENUM ('INTERNAL', 'EXTERNAL');

-- CreateEnum
CREATE TYPE "CalibrationResult" AS ENUM ('PASS', 'FAIL', 'CONDITIONAL');

-- CreateEnum
CREATE TYPE "CalibrationComplianceStatus" AS ENUM ('COMPLIANT', 'DUE_SOON', 'OVERDUE');

-- CreateEnum
CREATE TYPE "WeeklyCheckCycleStatus" AS ENUM ('OPEN', 'CLOSED');

-- CreateEnum
CREATE TYPE "WeeklyCheckItemStatus" AS ENUM ('PENDING', 'CONFIRMED', 'OVERDUE');

-- CreateEnum
CREATE TYPE "ConsumableCategory" AS ENUM ('SOLUTION', 'SOLID', 'BATTERY', 'OTHER');

-- CreateEnum
CREATE TYPE "StockTransactionType" AS ENUM ('RECEIVE', 'CONSUME', 'ADJUST', 'TRANSFER');

-- AlterEnum
ALTER TYPE "ActivityAction" ADD VALUE 'DQA_EQUIPMENT_STATUS_CHANGED';
ALTER TYPE "ActivityAction" ADD VALUE 'DQA_CALIBRATION_RECORDED';
ALTER TYPE "ActivityAction" ADD VALUE 'DQA_WEEKLY_CHECK_CONFIRMED';
ALTER TYPE "ActivityAction" ADD VALUE 'DQA_STOCK_TRANSACTION';

-- CreateTable
CREATE TABLE "DqaEquipmentProfile" (
    "id" TEXT NOT NULL,
    "assetId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "equipmentCode" TEXT NOT NULL,
    "managerTeamMemberId" TEXT,
    "operationalStatus" "DqaOperationalStatus" NOT NULL DEFAULT 'OPERATIONAL',
    "manualUrl" TEXT,
    "origin" TEXT,
    "consumableNotes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DqaEquipmentProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CalibrationRecord" (
    "id" TEXT NOT NULL,
    "assetId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "calibrationType" "CalibrationType" NOT NULL,
    "performedAt" TIMESTAMP(3) NOT NULL,
    "nextDueAt" TIMESTAMP(3),
    "result" "CalibrationResult" NOT NULL,
    "certificateUrl" TEXT,
    "failureReason" TEXT,
    "notes" TEXT,
    "performedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CalibrationRecord_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CalibrationSchedule" (
    "id" TEXT NOT NULL,
    "assetId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "intervalMonths" INTEGER NOT NULL DEFAULT 12,
    "calibrationType" "CalibrationType" NOT NULL DEFAULT 'EXTERNAL',
    "nextDueAt" TIMESTAMP(3),
    "lastRecordId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CalibrationSchedule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WeeklyCheckCycle" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "weekStartDate" TIMESTAMP(3) NOT NULL,
    "status" "WeeklyCheckCycleStatus" NOT NULL DEFAULT 'OPEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WeeklyCheckCycle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WeeklyCheckItem" (
    "id" TEXT NOT NULL,
    "cycleId" TEXT NOT NULL,
    "assetId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "assignedManagerId" TEXT,
    "status" "WeeklyCheckItemStatus" NOT NULL DEFAULT 'PENDING',
    "operationalStatus" "DqaOperationalStatus",
    "notes" TEXT,
    "confirmToken" TEXT,
    "confirmedAt" TIMESTAMP(3),
    "confirmedById" TEXT,
    "reminderSentAt" TIMESTAMP(3),
    "escalationSentAt" TIMESTAMP(3),
    "finalEscalationAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WeeklyCheckItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ConsumableItem" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" "ConsumableCategory" NOT NULL DEFAULT 'OTHER',
    "unitOfMeasure" TEXT NOT NULL,
    "reorderPoint" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "locationId" TEXT,
    "managerTeamMemberId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ConsumableItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StockBalance" (
    "id" TEXT NOT NULL,
    "consumableId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "locationId" TEXT,
    "quantityOnHand" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StockBalance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StockTransaction" (
    "id" TEXT NOT NULL,
    "consumableId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "type" "StockTransactionType" NOT NULL,
    "quantity" DOUBLE PRECISION NOT NULL,
    "notes" TEXT,
    "locationId" TEXT,
    "assetId" TEXT,
    "performedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StockTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EquipmentConsumable" (
    "id" TEXT NOT NULL,
    "assetId" TEXT NOT NULL,
    "consumableId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EquipmentConsumable_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RoomLayout" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "floorPlanImageUrl" TEXT NOT NULL,
    "width" INTEGER NOT NULL DEFAULT 1200,
    "height" INTEGER NOT NULL DEFAULT 800,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "RoomLayout_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LayoutZone" (
    "id" TEXT NOT NULL,
    "layoutId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "locationId" TEXT,
    "label" TEXT NOT NULL,
    "shape" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LayoutZone_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LayoutPin" (
    "id" TEXT NOT NULL,
    "layoutId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "assetId" TEXT,
    "consumableId" TEXT,
    "x" DOUBLE PRECISION NOT NULL,
    "y" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LayoutPin_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "DqaEquipmentProfile_assetId_key" ON "DqaEquipmentProfile"("assetId");
CREATE UNIQUE INDEX "DqaEquipmentProfile_organizationId_equipmentCode_key" ON "DqaEquipmentProfile"("organizationId", "equipmentCode");
CREATE INDEX "DqaEquipmentProfile_organizationId_operationalStatus_idx" ON "DqaEquipmentProfile"("organizationId", "operationalStatus");
CREATE INDEX "DqaEquipmentProfile_managerTeamMemberId_idx" ON "DqaEquipmentProfile"("managerTeamMemberId");

CREATE INDEX "CalibrationRecord_organizationId_assetId_idx" ON "CalibrationRecord"("organizationId", "assetId");
CREATE INDEX "CalibrationRecord_organizationId_nextDueAt_idx" ON "CalibrationRecord"("organizationId", "nextDueAt");
CREATE INDEX "CalibrationRecord_performedById_idx" ON "CalibrationRecord"("performedById");

CREATE UNIQUE INDEX "CalibrationSchedule_assetId_key" ON "CalibrationSchedule"("assetId");
CREATE UNIQUE INDEX "CalibrationSchedule_lastRecordId_key" ON "CalibrationSchedule"("lastRecordId");
CREATE INDEX "CalibrationSchedule_organizationId_nextDueAt_idx" ON "CalibrationSchedule"("organizationId", "nextDueAt");

CREATE UNIQUE INDEX "WeeklyCheckCycle_organizationId_weekStartDate_key" ON "WeeklyCheckCycle"("organizationId", "weekStartDate");
CREATE INDEX "WeeklyCheckCycle_organizationId_status_idx" ON "WeeklyCheckCycle"("organizationId", "status");

CREATE UNIQUE INDEX "WeeklyCheckItem_cycleId_assetId_key" ON "WeeklyCheckItem"("cycleId", "assetId");
CREATE UNIQUE INDEX "WeeklyCheckItem_confirmToken_key" ON "WeeklyCheckItem"("confirmToken");
CREATE INDEX "WeeklyCheckItem_organizationId_status_idx" ON "WeeklyCheckItem"("organizationId", "status");
CREATE INDEX "WeeklyCheckItem_assignedManagerId_status_idx" ON "WeeklyCheckItem"("assignedManagerId", "status");
CREATE INDEX "WeeklyCheckItem_confirmToken_idx" ON "WeeklyCheckItem"("confirmToken");

CREATE UNIQUE INDEX "ConsumableItem_organizationId_code_key" ON "ConsumableItem"("organizationId", "code");
CREATE INDEX "ConsumableItem_organizationId_category_idx" ON "ConsumableItem"("organizationId", "category");
CREATE INDEX "ConsumableItem_locationId_idx" ON "ConsumableItem"("locationId");
CREATE INDEX "ConsumableItem_managerTeamMemberId_idx" ON "ConsumableItem"("managerTeamMemberId");

CREATE UNIQUE INDEX "StockBalance_consumableId_locationId_key" ON "StockBalance"("consumableId", "locationId");
CREATE INDEX "StockBalance_organizationId_idx" ON "StockBalance"("organizationId");

CREATE INDEX "StockTransaction_organizationId_consumableId_createdAt_idx" ON "StockTransaction"("organizationId", "consumableId", "createdAt");
CREATE INDEX "StockTransaction_organizationId_type_createdAt_idx" ON "StockTransaction"("organizationId", "type", "createdAt");
CREATE INDEX "StockTransaction_assetId_idx" ON "StockTransaction"("assetId");
CREATE INDEX "StockTransaction_performedById_idx" ON "StockTransaction"("performedById");

CREATE UNIQUE INDEX "EquipmentConsumable_assetId_consumableId_key" ON "EquipmentConsumable"("assetId", "consumableId");
CREATE INDEX "EquipmentConsumable_organizationId_idx" ON "EquipmentConsumable"("organizationId");
CREATE INDEX "EquipmentConsumable_consumableId_idx" ON "EquipmentConsumable"("consumableId");

CREATE INDEX "RoomLayout_organizationId_idx" ON "RoomLayout"("organizationId");
CREATE INDEX "LayoutZone_layoutId_idx" ON "LayoutZone"("layoutId");
CREATE INDEX "LayoutZone_organizationId_idx" ON "LayoutZone"("organizationId");
CREATE INDEX "LayoutZone_locationId_idx" ON "LayoutZone"("locationId");
CREATE INDEX "LayoutPin_layoutId_idx" ON "LayoutPin"("layoutId");
CREATE INDEX "LayoutPin_organizationId_idx" ON "LayoutPin"("organizationId");
CREATE INDEX "LayoutPin_assetId_idx" ON "LayoutPin"("assetId");
CREATE INDEX "LayoutPin_consumableId_idx" ON "LayoutPin"("consumableId");

-- AddForeignKey
ALTER TABLE "DqaEquipmentProfile" ADD CONSTRAINT "DqaEquipmentProfile_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "Asset"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "DqaEquipmentProfile" ADD CONSTRAINT "DqaEquipmentProfile_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "DqaEquipmentProfile" ADD CONSTRAINT "DqaEquipmentProfile_managerTeamMemberId_fkey" FOREIGN KEY ("managerTeamMemberId") REFERENCES "TeamMember"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "CalibrationRecord" ADD CONSTRAINT "CalibrationRecord_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "Asset"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CalibrationRecord" ADD CONSTRAINT "CalibrationRecord_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CalibrationRecord" ADD CONSTRAINT "CalibrationRecord_performedById_fkey" FOREIGN KEY ("performedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "CalibrationSchedule" ADD CONSTRAINT "CalibrationSchedule_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "Asset"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CalibrationSchedule" ADD CONSTRAINT "CalibrationSchedule_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CalibrationSchedule" ADD CONSTRAINT "CalibrationSchedule_lastRecordId_fkey" FOREIGN KEY ("lastRecordId") REFERENCES "CalibrationRecord"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "WeeklyCheckCycle" ADD CONSTRAINT "WeeklyCheckCycle_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "WeeklyCheckItem" ADD CONSTRAINT "WeeklyCheckItem_cycleId_fkey" FOREIGN KEY ("cycleId") REFERENCES "WeeklyCheckCycle"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "WeeklyCheckItem" ADD CONSTRAINT "WeeklyCheckItem_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "Asset"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "WeeklyCheckItem" ADD CONSTRAINT "WeeklyCheckItem_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "WeeklyCheckItem" ADD CONSTRAINT "WeeklyCheckItem_assignedManagerId_fkey" FOREIGN KEY ("assignedManagerId") REFERENCES "TeamMember"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "WeeklyCheckItem" ADD CONSTRAINT "WeeklyCheckItem_confirmedById_fkey" FOREIGN KEY ("confirmedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "ConsumableItem" ADD CONSTRAINT "ConsumableItem_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ConsumableItem" ADD CONSTRAINT "ConsumableItem_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "ConsumableItem" ADD CONSTRAINT "ConsumableItem_managerTeamMemberId_fkey" FOREIGN KEY ("managerTeamMemberId") REFERENCES "TeamMember"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "StockBalance" ADD CONSTRAINT "StockBalance_consumableId_fkey" FOREIGN KEY ("consumableId") REFERENCES "ConsumableItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "StockBalance" ADD CONSTRAINT "StockBalance_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "StockBalance" ADD CONSTRAINT "StockBalance_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "StockTransaction" ADD CONSTRAINT "StockTransaction_consumableId_fkey" FOREIGN KEY ("consumableId") REFERENCES "ConsumableItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "StockTransaction" ADD CONSTRAINT "StockTransaction_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "StockTransaction" ADD CONSTRAINT "StockTransaction_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "StockTransaction" ADD CONSTRAINT "StockTransaction_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "Asset"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "StockTransaction" ADD CONSTRAINT "StockTransaction_performedById_fkey" FOREIGN KEY ("performedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "EquipmentConsumable" ADD CONSTRAINT "EquipmentConsumable_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "Asset"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "EquipmentConsumable" ADD CONSTRAINT "EquipmentConsumable_consumableId_fkey" FOREIGN KEY ("consumableId") REFERENCES "ConsumableItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "EquipmentConsumable" ADD CONSTRAINT "EquipmentConsumable_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "RoomLayout" ADD CONSTRAINT "RoomLayout_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "LayoutZone" ADD CONSTRAINT "LayoutZone_layoutId_fkey" FOREIGN KEY ("layoutId") REFERENCES "RoomLayout"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "LayoutZone" ADD CONSTRAINT "LayoutZone_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "LayoutZone" ADD CONSTRAINT "LayoutZone_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "LayoutPin" ADD CONSTRAINT "LayoutPin_layoutId_fkey" FOREIGN KEY ("layoutId") REFERENCES "RoomLayout"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "LayoutPin" ADD CONSTRAINT "LayoutPin_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "LayoutPin" ADD CONSTRAINT "LayoutPin_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "Asset"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "LayoutPin" ADD CONSTRAINT "LayoutPin_consumableId_fkey" FOREIGN KEY ("consumableId") REFERENCES "ConsumableItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
