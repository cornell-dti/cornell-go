/*
  Warnings:

  - Added the required column `college` to the `User` table without a default value. This is not possible if the table is not empty.
  - Added the required column `major` to the `User` table without a default value. This is not possible if the table is not empty.

*/
-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "LocationType" ADD VALUE 'CENTRAL_CAMPUS';
ALTER TYPE "LocationType" ADD VALUE 'CORNELL_ATHLETICS';
ALTER TYPE "LocationType" ADD VALUE 'VET_SCHOOL';

-- DropForeignKey
ALTER TABLE "AchievementTracker" DROP CONSTRAINT "AchievementTracker_achievementId_fkey";

-- DropForeignKey
ALTER TABLE "AchievementTracker" DROP CONSTRAINT "AchievementTracker_userId_fkey";

-- DropForeignKey
ALTER TABLE "EventTracker" DROP CONSTRAINT "EventTracker_curChallengeId_fkey";

-- AlterTable
ALTER TABLE "EventTracker" ALTER COLUMN "curChallengeId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "college" TEXT NOT NULL,
ADD COLUMN     "interests" TEXT[],
ADD COLUMN     "major" TEXT NOT NULL;

-- CreateTable
CREATE TABLE "_AchievementToOrganization" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "_AchievementToOrganization_AB_unique" ON "_AchievementToOrganization"("A", "B");

-- CreateIndex
CREATE INDEX "_AchievementToOrganization_B_index" ON "_AchievementToOrganization"("B");

-- AddForeignKey
ALTER TABLE "EventTracker" ADD CONSTRAINT "EventTracker_curChallengeId_fkey" FOREIGN KEY ("curChallengeId") REFERENCES "Challenge"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AchievementTracker" ADD CONSTRAINT "AchievementTracker_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AchievementTracker" ADD CONSTRAINT "AchievementTracker_achievementId_fkey" FOREIGN KEY ("achievementId") REFERENCES "Achievement"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_AchievementToOrganization" ADD CONSTRAINT "_AchievementToOrganization_A_fkey" FOREIGN KEY ("A") REFERENCES "Achievement"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_AchievementToOrganization" ADD CONSTRAINT "_AchievementToOrganization_B_fkey" FOREIGN KEY ("B") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;
