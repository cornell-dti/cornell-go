/*
  Warnings:

  - You are about to drop the column `defaultChallengeId` on the `EventBase` table. All the data in the column will be lost.
  - You are about to drop the column `minimumScore` on the `EventBase` table. All the data in the column will be lost.
  - You are about to drop the column `rewardType` on the `EventBase` table. All the data in the column will be lost.
  - You are about to drop the column `defaultEventId` on the `Organization` table. All the data in the column will be lost.
  - You are about to drop the `EventReward` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `_events` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `_manager` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `_participant` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `_player` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `difficulty` to the `EventBase` table without a default value. This is not possible if the table is not empty.
  - Added the required column `latitude` to the `EventBase` table without a default value. This is not possible if the table is not empty.
  - Added the required column `longitude` to the `EventBase` table without a default value. This is not possible if the table is not empty.
  - Added the required column `timeLimitation` to the `EventBase` table without a default value. This is not possible if the table is not empty.
  - Added the required column `enrollmentType` to the `User` table without a default value. This is not possible if the table is not empty.
  - Added the required column `year` to the `User` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "TimeLimitationType" AS ENUM ('LIMITED_TIME', 'PERPETUAL');

-- CreateEnum
CREATE TYPE "EnrollmentType" AS ENUM ('UNDERGRADUATE', 'GRADUATE', 'FACULTY', 'ALUMNI');

-- CreateEnum
CREATE TYPE "LocationType" AS ENUM ('ENG_QUAD', 'ARTS_QUAD', 'AG_QUAD', 'NORTH_CAMPUS', 'WEST_CAMPUS', 'COLLEGETOWN', 'ITHACA_COMMONS', 'ANY');

-- CreateEnum
CREATE TYPE "AchievementType" AS ENUM ('TOTAL_POINTS', 'TOTAL_CHALLENGES', 'TOTAL_JOURNEYS', 'TOTAL_CHALLENGES_OR_JOURNEYS');

-- CreateEnum
CREATE TYPE "DifficultyMode" AS ENUM ('EASY', 'NORMAL', 'HARD');

-- CreateEnum
CREATE TYPE "SessionLogEvent" AS ENUM ('JOIN_GROUP', 'LEAVE_GROUP', 'LOGIN_USER', 'CREATE_USER', 'DELETE_USER', 'EDIT_USERNAME', 'SELECT_EVENT', 'DELETE_EVENT', 'SET_CHALLENGE', 'DELETE_CHALLENGE', 'COMPLETE_CHALLENGE', 'DISCONNECT');

-- DropForeignKey
ALTER TABLE "EventBase" DROP CONSTRAINT "EventBase_defaultChallengeId_fkey";

-- DropForeignKey
ALTER TABLE "EventReward" DROP CONSTRAINT "EventReward_eventId_fkey";

-- DropForeignKey
ALTER TABLE "EventReward" DROP CONSTRAINT "EventReward_userId_fkey";

-- DropForeignKey
ALTER TABLE "Organization" DROP CONSTRAINT "Organization_defaultEventId_fkey";

-- DropForeignKey
ALTER TABLE "_events" DROP CONSTRAINT "_events_A_fkey";

-- DropForeignKey
ALTER TABLE "_events" DROP CONSTRAINT "_events_B_fkey";

-- DropForeignKey
ALTER TABLE "_manager" DROP CONSTRAINT "_manager_A_fkey";

-- DropForeignKey
ALTER TABLE "_manager" DROP CONSTRAINT "_manager_B_fkey";

-- DropForeignKey
ALTER TABLE "_participant" DROP CONSTRAINT "_participant_A_fkey";

-- DropForeignKey
ALTER TABLE "_participant" DROP CONSTRAINT "_participant_B_fkey";

-- DropForeignKey
ALTER TABLE "_player" DROP CONSTRAINT "_player_A_fkey";

-- DropForeignKey
ALTER TABLE "_player" DROP CONSTRAINT "_player_B_fkey";

-- DropIndex
DROP INDEX "EventBase_defaultChallengeId_key";

-- AlterTable
ALTER TABLE "EventBase" DROP COLUMN "defaultChallengeId",
DROP COLUMN "minimumScore",
DROP COLUMN "rewardType",
ADD COLUMN     "difficulty" "DifficultyMode" NOT NULL,
ADD COLUMN     "latitude" DOUBLE PRECISION NOT NULL,
ADD COLUMN     "longitude" DOUBLE PRECISION NOT NULL,
ADD COLUMN     "timeLimitation" "TimeLimitationType" NOT NULL;

-- AlterTable
ALTER TABLE "Organization" DROP COLUMN "defaultEventId";

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "enrollmentType" "EnrollmentType" NOT NULL,
ADD COLUMN     "isBanned" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "year" TEXT NOT NULL;

-- DropTable
DROP TABLE "EventReward";

-- DropTable
DROP TABLE "_events";

-- DropTable
DROP TABLE "_manager";

-- DropTable
DROP TABLE "_participant";

-- DropTable
DROP TABLE "_player";

-- DropEnum
DROP TYPE "EventRewardType";

-- CreateTable
CREATE TABLE "SessionLogEntry" (
    "id" TEXT NOT NULL,
    "eventType" "SessionLogEvent" NOT NULL,
    "data" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" TEXT,

    CONSTRAINT "SessionLogEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Achievement" (
    "id" TEXT NOT NULL,
    "requiredPoints" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "linkedEventId" TEXT,
    "locationType" "LocationType" NOT NULL,
    "achievementType" "AchievementType" NOT NULL,

    CONSTRAINT "Achievement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AchievementTracker" (
    "id" TEXT NOT NULL,
    "progress" INTEGER NOT NULL,
    "dateComplete" TIMESTAMP(3),
    "achievementId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "AchievementTracker_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "_EventBaseToUser" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "_eventOrgs" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "_prevChallengeParticipant" (
    "A" INTEGER NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "_orgToUser" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "_orgManager" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "_EventBaseToUser_AB_unique" ON "_EventBaseToUser"("A", "B");

-- CreateIndex
CREATE INDEX "_EventBaseToUser_B_index" ON "_EventBaseToUser"("B");

-- CreateIndex
CREATE UNIQUE INDEX "_eventOrgs_AB_unique" ON "_eventOrgs"("A", "B");

-- CreateIndex
CREATE INDEX "_eventOrgs_B_index" ON "_eventOrgs"("B");

-- CreateIndex
CREATE UNIQUE INDEX "_prevChallengeParticipant_AB_unique" ON "_prevChallengeParticipant"("A", "B");

-- CreateIndex
CREATE INDEX "_prevChallengeParticipant_B_index" ON "_prevChallengeParticipant"("B");

-- CreateIndex
CREATE UNIQUE INDEX "_orgToUser_AB_unique" ON "_orgToUser"("A", "B");

-- CreateIndex
CREATE INDEX "_orgToUser_B_index" ON "_orgToUser"("B");

-- CreateIndex
CREATE UNIQUE INDEX "_orgManager_AB_unique" ON "_orgManager"("A", "B");

-- CreateIndex
CREATE INDEX "_orgManager_B_index" ON "_orgManager"("B");

-- AddForeignKey
ALTER TABLE "SessionLogEntry" ADD CONSTRAINT "SessionLogEntry_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Achievement" ADD CONSTRAINT "Achievement_linkedEventId_fkey" FOREIGN KEY ("linkedEventId") REFERENCES "EventBase"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AchievementTracker" ADD CONSTRAINT "AchievementTracker_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AchievementTracker" ADD CONSTRAINT "AchievementTracker_achievementId_fkey" FOREIGN KEY ("achievementId") REFERENCES "Achievement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_EventBaseToUser" ADD CONSTRAINT "_EventBaseToUser_A_fkey" FOREIGN KEY ("A") REFERENCES "EventBase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_EventBaseToUser" ADD CONSTRAINT "_EventBaseToUser_B_fkey" FOREIGN KEY ("B") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_eventOrgs" ADD CONSTRAINT "_eventOrgs_A_fkey" FOREIGN KEY ("A") REFERENCES "EventBase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_eventOrgs" ADD CONSTRAINT "_eventOrgs_B_fkey" FOREIGN KEY ("B") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_prevChallengeParticipant" ADD CONSTRAINT "_prevChallengeParticipant_A_fkey" FOREIGN KEY ("A") REFERENCES "PrevChallenge"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_prevChallengeParticipant" ADD CONSTRAINT "_prevChallengeParticipant_B_fkey" FOREIGN KEY ("B") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_orgToUser" ADD CONSTRAINT "_orgToUser_A_fkey" FOREIGN KEY ("A") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_orgToUser" ADD CONSTRAINT "_orgToUser_B_fkey" FOREIGN KEY ("B") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_orgManager" ADD CONSTRAINT "_orgManager_A_fkey" FOREIGN KEY ("A") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_orgManager" ADD CONSTRAINT "_orgManager_B_fkey" FOREIGN KEY ("B") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
