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
-- AlterTable
ALTER TABLE "EventBase" ALTER COLUMN "longDescription" DROP DEFAULT;

-- AlterTable
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "fcmToken" TEXT;

-- AlterTable (IF EXISTS to handle databases where these constraints have different names)
ALTER TABLE "_AchievementToOrganization" DROP CONSTRAINT IF EXISTS "_AchievementToOrganization_AB_pkey";

-- AlterTable
ALTER TABLE "_EventBaseToUser" DROP CONSTRAINT IF EXISTS "_EventBaseToUser_AB_pkey";

-- AlterTable
ALTER TABLE "_eventOrgs" DROP CONSTRAINT IF EXISTS "_eventOrgs_AB_pkey";

-- AlterTable
ALTER TABLE "_orgManager" DROP CONSTRAINT IF EXISTS "_orgManager_AB_pkey";

-- AlterTable
ALTER TABLE "_orgToUser" DROP CONSTRAINT IF EXISTS "_orgToUser_AB_pkey";

-- AlterTable
ALTER TABLE "_prevChallengeParticipant" DROP CONSTRAINT IF EXISTS "_prevChallengeParticipant_AB_pkey";

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "_AchievementToOrganization_AB_unique" ON "_AchievementToOrganization"("A", "B");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "_EventBaseToUser_AB_unique" ON "_EventBaseToUser"("A", "B");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "_eventOrgs_AB_unique" ON "_eventOrgs"("A", "B");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "_orgManager_AB_unique" ON "_orgManager"("A", "B");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "_orgToUser_AB_unique" ON "_orgToUser"("A", "B");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "_prevChallengeParticipant_AB_unique" ON "_prevChallengeParticipant"("A", "B");
