-- CreateEnum
CREATE TYPE "AuthType" AS ENUM ('GOOGLE', 'APPLE', 'DEVICE', 'NONE');

-- CreateEnum
CREATE TYPE "TimeLimitationType" AS ENUM ('LIMITED_TIME', 'PERPETUAL');

-- CreateEnum
CREATE TYPE "EnrollmentType" AS ENUM ('UNDERGRADUATE', 'GRADUATE', 'FACULTY', 'ALUMNI', 'GUEST');

-- CreateEnum
CREATE TYPE "LocationType" AS ENUM ('ENG_QUAD', 'ARTS_QUAD', 'AG_QUAD', 'NORTH_CAMPUS', 'WEST_CAMPUS', 'COLLEGETOWN', 'ITHACA_COMMONS', 'ANY');

-- CreateEnum
CREATE TYPE "AchievementType" AS ENUM ('TOTAL_POINTS', 'TOTAL_CHALLENGES', 'TOTAL_JOURNEYS', 'TOTAL_CHALLENGES_OR_JOURNEYS');

-- CreateEnum
CREATE TYPE "DifficultyMode" AS ENUM ('EASY', 'NORMAL', 'HARD');

-- CreateEnum
CREATE TYPE "SessionLogEvent" AS ENUM ('JOIN_GROUP', 'LEAVE_GROUP', 'LOGIN_USER', 'CREATE_USER', 'DELETE_USER', 'EDIT_USERNAME', 'SELECT_EVENT', 'DELETE_EVENT', 'SET_CHALLENGE', 'DELETE_CHALLENGE', 'COMPLETE_CHALLENGE', 'DISCONNECT');

-- CreateEnum
CREATE TYPE "OrganizationSpecialUsage" AS ENUM ('DEVICE_LOGIN', 'CORNELL_LOGIN', 'NONE');

-- CreateEnum
CREATE TYPE "EventCategoryType" AS ENUM ('FOOD', 'NATURE', 'HISTORICAL', 'CAFE', 'DININGHALL', 'DORM');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "subject" TEXT NOT NULL DEFAULT 'User',
    "authToken" TEXT NOT NULL,
    "authType" "AuthType" NOT NULL,
    "username" TEXT NOT NULL,
    "year" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "hashedRefreshToken" TEXT NOT NULL,
    "administrator" BOOLEAN NOT NULL,
    "enrollmentType" "EnrollmentType" NOT NULL,
    "score" INTEGER NOT NULL,
    "isBanned" BOOLEAN NOT NULL DEFAULT false,
    "groupId" TEXT NOT NULL,
    "isRanked" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Group" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "subject" TEXT NOT NULL DEFAULT 'Group',
    "friendlyId" TEXT NOT NULL,
    "hostId" TEXT,
    "curEventId" TEXT NOT NULL,

    CONSTRAINT "Group_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Challenge" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "subject" TEXT NOT NULL DEFAULT 'Challenge',
    "linkedEventId" TEXT,
    "eventIndex" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "location" "LocationType" NOT NULL,
    "description" TEXT NOT NULL,
    "points" INTEGER NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "awardingRadius" DOUBLE PRECISION NOT NULL,
    "closeRadius" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "Challenge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventBase" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "subject" TEXT NOT NULL DEFAULT 'EventBase',
    "requiredMembers" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "timeLimitation" "TimeLimitationType" NOT NULL,
    "indexable" BOOLEAN NOT NULL,
    "endTime" TIMESTAMP(3) NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "difficulty" "DifficultyMode" NOT NULL,
    "category" "EventCategoryType" NOT NULL,

    CONSTRAINT "EventBase_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventTracker" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "subject" TEXT NOT NULL DEFAULT 'EventTracker',
    "userId" TEXT NOT NULL,
    "score" INTEGER NOT NULL,
    "hintsUsed" INTEGER NOT NULL,
    "isRankedForEvent" BOOLEAN NOT NULL DEFAULT true,
    "eventId" TEXT NOT NULL,
    "curChallengeId" TEXT NOT NULL,

    CONSTRAINT "EventTracker_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PrevChallenge" (
    "id" SERIAL NOT NULL,
    "subject" TEXT NOT NULL DEFAULT 'PrevChallenge',
    "userId" TEXT NOT NULL,
    "challengeId" TEXT NOT NULL,
    "trackerId" TEXT NOT NULL,
    "hintsUsed" INTEGER NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PrevChallenge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Organization" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "subject" TEXT NOT NULL DEFAULT 'Organization',
    "name" TEXT NOT NULL,
    "accessCode" TEXT NOT NULL,
    "specialUsage" "OrganizationSpecialUsage" NOT NULL,

    CONSTRAINT "Organization_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SessionLogEntry" (
    "id" TEXT NOT NULL,
    "subject" TEXT NOT NULL DEFAULT 'SessionLogEntry',
    "eventType" "SessionLogEvent" NOT NULL,
    "data" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" TEXT,

    CONSTRAINT "SessionLogEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Achievement" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "subject" TEXT NOT NULL DEFAULT 'Achievement',
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
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "subject" TEXT NOT NULL DEFAULT 'AchievementTracker',
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
CREATE UNIQUE INDEX "User_authToken_key" ON "User"("authToken");

-- CreateIndex
CREATE UNIQUE INDEX "Group_friendlyId_key" ON "Group"("friendlyId");

-- CreateIndex
CREATE UNIQUE INDEX "Group_hostId_key" ON "Group"("hostId");

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
ALTER TABLE "User" ADD CONSTRAINT "User_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Group" ADD CONSTRAINT "Group_hostId_fkey" FOREIGN KEY ("hostId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Group" ADD CONSTRAINT "Group_curEventId_fkey" FOREIGN KEY ("curEventId") REFERENCES "EventBase"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Challenge" ADD CONSTRAINT "Challenge_linkedEventId_fkey" FOREIGN KEY ("linkedEventId") REFERENCES "EventBase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventTracker" ADD CONSTRAINT "EventTracker_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventTracker" ADD CONSTRAINT "EventTracker_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "EventBase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventTracker" ADD CONSTRAINT "EventTracker_curChallengeId_fkey" FOREIGN KEY ("curChallengeId") REFERENCES "Challenge"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PrevChallenge" ADD CONSTRAINT "PrevChallenge_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PrevChallenge" ADD CONSTRAINT "PrevChallenge_challengeId_fkey" FOREIGN KEY ("challengeId") REFERENCES "Challenge"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PrevChallenge" ADD CONSTRAINT "PrevChallenge_trackerId_fkey" FOREIGN KEY ("trackerId") REFERENCES "EventTracker"("id") ON DELETE CASCADE ON UPDATE CASCADE;

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
