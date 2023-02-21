/*
  Warnings:

  - You are about to drop the column `isDefault` on the `EventBase` table. All the data in the column will be lost.
  - You are about to drop the column `skippingEnabled` on the `EventBase` table. All the data in the column will be lost.
  - You are about to drop the column `cooldownEnd` on the `EventTracker` table. All the data in the column will be lost.
  - You are about to drop the column `canEditUsername` on the `Organization` table. All the data in the column will be lost.
  - You are about to drop the column `displayName` on the `Organization` table. All the data in the column will be lost.
  - You are about to drop the column `adminGranted` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `adminRequested` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `generatedById` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `restrictedById` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `superuser` on the `User` table. All the data in the column will be lost.
  - You are about to drop the `_EventBaseToOrganization` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[defaultChallengeId]` on the table `EventBase` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `defaultChallengeId` to the `EventBase` table without a default value. This is not possible if the table is not empty.
  - Added the required column `accessCode` to the `Organization` table without a default value. This is not possible if the table is not empty.
  - Added the required column `defaultEventId` to the `Organization` table without a default value. This is not possible if the table is not empty.
  - Added the required column `specialUsage` to the `Organization` table without a default value. This is not possible if the table is not empty.
  - Added the required column `administrator` to the `User` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "OrganizationSpecialUsage" AS ENUM ('DEVICE_LOGIN', 'CORNELL_LOGIN', 'NONE');

-- DropForeignKey
ALTER TABLE "User" DROP CONSTRAINT "User_generatedById_fkey";

-- DropForeignKey
ALTER TABLE "User" DROP CONSTRAINT "User_restrictedById_fkey";

-- DropForeignKey
ALTER TABLE "_EventBaseToOrganization" DROP CONSTRAINT "_EventBaseToOrganization_A_fkey";

-- DropForeignKey
ALTER TABLE "_EventBaseToOrganization" DROP CONSTRAINT "_EventBaseToOrganization_B_fkey";

-- AlterTable
ALTER TABLE "EventBase" DROP COLUMN "isDefault",
DROP COLUMN "skippingEnabled",
ADD COLUMN     "defaultChallengeId" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "EventTracker" DROP COLUMN "cooldownEnd";

-- AlterTable
ALTER TABLE "Organization" DROP COLUMN "canEditUsername",
DROP COLUMN "displayName",
ADD COLUMN     "accessCode" TEXT NOT NULL,
ADD COLUMN     "defaultEventId" TEXT NOT NULL,
ADD COLUMN     "specialUsage" "OrganizationSpecialUsage" NOT NULL;

-- AlterTable
ALTER TABLE "User" DROP COLUMN "adminGranted",
DROP COLUMN "adminRequested",
DROP COLUMN "generatedById",
DROP COLUMN "restrictedById",
DROP COLUMN "superuser",
ADD COLUMN     "administrator" BOOLEAN NOT NULL;

-- DropTable
DROP TABLE "_EventBaseToOrganization";

-- CreateTable
CREATE TABLE "_events" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "_player" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "_manager" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "_events_AB_unique" ON "_events"("A", "B");

-- CreateIndex
CREATE INDEX "_events_B_index" ON "_events"("B");

-- CreateIndex
CREATE UNIQUE INDEX "_player_AB_unique" ON "_player"("A", "B");

-- CreateIndex
CREATE INDEX "_player_B_index" ON "_player"("B");

-- CreateIndex
CREATE UNIQUE INDEX "_manager_AB_unique" ON "_manager"("A", "B");

-- CreateIndex
CREATE INDEX "_manager_B_index" ON "_manager"("B");

-- CreateIndex
CREATE UNIQUE INDEX "EventBase_defaultChallengeId_key" ON "EventBase"("defaultChallengeId");

-- AddForeignKey
ALTER TABLE "EventBase" ADD CONSTRAINT "EventBase_defaultChallengeId_fkey" FOREIGN KEY ("defaultChallengeId") REFERENCES "Challenge"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Organization" ADD CONSTRAINT "Organization_defaultEventId_fkey" FOREIGN KEY ("defaultEventId") REFERENCES "EventBase"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_events" ADD CONSTRAINT "_events_A_fkey" FOREIGN KEY ("A") REFERENCES "EventBase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_events" ADD CONSTRAINT "_events_B_fkey" FOREIGN KEY ("B") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_player" ADD CONSTRAINT "_player_A_fkey" FOREIGN KEY ("A") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_player" ADD CONSTRAINT "_player_B_fkey" FOREIGN KEY ("B") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_manager" ADD CONSTRAINT "_manager_A_fkey" FOREIGN KEY ("A") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_manager" ADD CONSTRAINT "_manager_B_fkey" FOREIGN KEY ("B") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
