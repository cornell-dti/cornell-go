/*
  Warnings:

  - The primary key for the `_AchievementToOrganization` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The primary key for the `_EventBaseToUser` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The primary key for the `_eventOrgs` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The primary key for the `_orgManager` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The primary key for the `_orgToUser` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The primary key for the `_prevChallengeParticipant` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - A unique constraint covering the columns `[A,B]` on the table `_AchievementToOrganization` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[A,B]` on the table `_EventBaseToUser` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[A,B]` on the table `_eventOrgs` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[A,B]` on the table `_orgManager` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[A,B]` on the table `_orgToUser` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[A,B]` on the table `_prevChallengeParticipant` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "BearSlot" AS ENUM ('EYES', 'MOUTH', 'COLOR', 'ACCESSORY');

-- AlterTable
ALTER TABLE "EventBase" ALTER COLUMN "longDescription" DROP DEFAULT;

-- AlterTable
ALTER TABLE "_AchievementToOrganization" DROP CONSTRAINT "_AchievementToOrganization_AB_pkey";

-- AlterTable
ALTER TABLE "_EventBaseToUser" DROP CONSTRAINT "_EventBaseToUser_AB_pkey";

-- AlterTable
ALTER TABLE "_eventOrgs" DROP CONSTRAINT "_eventOrgs_AB_pkey";

-- AlterTable
ALTER TABLE "_orgManager" DROP CONSTRAINT "_orgManager_AB_pkey";

-- AlterTable
ALTER TABLE "_orgToUser" DROP CONSTRAINT "_orgToUser_AB_pkey";

-- AlterTable
ALTER TABLE "_prevChallengeParticipant" DROP CONSTRAINT "_prevChallengeParticipant_AB_pkey";

-- CreateTable
CREATE TABLE "BearItem" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "name" TEXT NOT NULL,
    "slot" "BearSlot" NOT NULL,
    "cost" INTEGER NOT NULL,
    "assetKey" TEXT NOT NULL,
    "mimeType" TEXT,
    "zIndex" INTEGER,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "BearItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserBearInventory" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "userId" TEXT NOT NULL,
    "bearItemId" TEXT NOT NULL,
    "acquiredDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserBearInventory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserBearEquipped" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "userId" TEXT NOT NULL,
    "bearItemId" TEXT NOT NULL,
    "slot" "BearSlot" NOT NULL,

    CONSTRAINT "UserBearEquipped_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "UserBearInventory_userId_bearItemId_key" ON "UserBearInventory"("userId", "bearItemId");

-- CreateIndex
CREATE UNIQUE INDEX "UserBearEquipped_userId_slot_key" ON "UserBearEquipped"("userId", "slot");

-- CreateIndex
CREATE UNIQUE INDEX "_AchievementToOrganization_AB_unique" ON "_AchievementToOrganization"("A", "B");

-- CreateIndex
CREATE UNIQUE INDEX "_EventBaseToUser_AB_unique" ON "_EventBaseToUser"("A", "B");

-- CreateIndex
CREATE UNIQUE INDEX "_eventOrgs_AB_unique" ON "_eventOrgs"("A", "B");

-- CreateIndex
CREATE UNIQUE INDEX "_orgManager_AB_unique" ON "_orgManager"("A", "B");

-- CreateIndex
CREATE UNIQUE INDEX "_orgToUser_AB_unique" ON "_orgToUser"("A", "B");

-- CreateIndex
CREATE UNIQUE INDEX "_prevChallengeParticipant_AB_unique" ON "_prevChallengeParticipant"("A", "B");

-- AddForeignKey
ALTER TABLE "UserBearInventory" ADD CONSTRAINT "UserBearInventory_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserBearInventory" ADD CONSTRAINT "UserBearInventory_bearItemId_fkey" FOREIGN KEY ("bearItemId") REFERENCES "BearItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserBearEquipped" ADD CONSTRAINT "UserBearEquipped_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserBearEquipped" ADD CONSTRAINT "UserBearEquipped_bearItemId_fkey" FOREIGN KEY ("bearItemId") REFERENCES "BearItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
