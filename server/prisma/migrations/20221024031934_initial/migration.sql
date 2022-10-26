-- CreateEnum
CREATE TYPE "AuthType" AS ENUM ('GOOGLE', 'APPLE', 'DEVICE', 'NONE');

-- CreateEnum
CREATE TYPE "EventRewardType" AS ENUM ('LIMITED_TIME', 'PERPETUAL');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "authToken" TEXT NOT NULL,
    "authType" "AuthType" NOT NULL,
    "username" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "hashedRefreshToken" TEXT NOT NULL,
    "superuser" BOOLEAN NOT NULL,
    "adminGranted" BOOLEAN NOT NULL,
    "adminRequested" BOOLEAN NOT NULL,
    "score" INTEGER NOT NULL,
    "groupId" TEXT NOT NULL,
    "restrictedById" TEXT,
    "generatedById" TEXT,
    "isRanked" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Group" (
    "id" TEXT NOT NULL,
    "friendlyId" TEXT NOT NULL,
    "hostId" TEXT,
    "curEventId" TEXT NOT NULL,

    CONSTRAINT "Group_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Challenge" (
    "id" TEXT NOT NULL,
    "linkedEventId" TEXT NOT NULL,
    "eventIndex" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
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
    "requiredMembers" INTEGER NOT NULL,
    "skippingEnabled" BOOLEAN NOT NULL,
    "isDefault" BOOLEAN NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "rewardType" "EventRewardType" NOT NULL,
    "indexable" BOOLEAN NOT NULL,
    "endTime" TIMESTAMP(3) NOT NULL,
    "minimumScore" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "EventBase_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventReward" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "eventId" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "redeemInfo" TEXT NOT NULL,
    "isRedeemed" BOOLEAN NOT NULL,

    CONSTRAINT "EventReward_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventTracker" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "score" INTEGER NOT NULL,
    "isRankedForEvent" BOOLEAN NOT NULL DEFAULT true,
    "cooldownEnd" TIMESTAMP(3) NOT NULL,
    "eventId" TEXT NOT NULL,
    "curChallengeId" TEXT NOT NULL,

    CONSTRAINT "EventTracker_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PrevChallenge" (
    "id" SERIAL NOT NULL,
    "userId" TEXT NOT NULL,
    "challengeId" TEXT NOT NULL,
    "trackerId" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PrevChallenge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RestrictionGroup" (
    "id" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "canEditUsername" BOOLEAN NOT NULL,

    CONSTRAINT "RestrictionGroup_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "_EventBaseToRestrictionGroup" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "_participant" (
    "A" INTEGER NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "Group_friendlyId_key" ON "Group"("friendlyId");

-- CreateIndex
CREATE UNIQUE INDEX "Group_hostId_key" ON "Group"("hostId");

-- CreateIndex
CREATE UNIQUE INDEX "EventBase_isDefault_key" ON "EventBase"("isDefault");

-- CreateIndex
CREATE UNIQUE INDEX "_EventBaseToRestrictionGroup_AB_unique" ON "_EventBaseToRestrictionGroup"("A", "B");

-- CreateIndex
CREATE INDEX "_EventBaseToRestrictionGroup_B_index" ON "_EventBaseToRestrictionGroup"("B");

-- CreateIndex
CREATE UNIQUE INDEX "_participant_AB_unique" ON "_participant"("A", "B");

-- CreateIndex
CREATE INDEX "_participant_B_index" ON "_participant"("B");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_restrictedById_fkey" FOREIGN KEY ("restrictedById") REFERENCES "RestrictionGroup"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_generatedById_fkey" FOREIGN KEY ("generatedById") REFERENCES "RestrictionGroup"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Group" ADD CONSTRAINT "Group_hostId_fkey" FOREIGN KEY ("hostId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Group" ADD CONSTRAINT "Group_curEventId_fkey" FOREIGN KEY ("curEventId") REFERENCES "EventBase"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Challenge" ADD CONSTRAINT "Challenge_linkedEventId_fkey" FOREIGN KEY ("linkedEventId") REFERENCES "EventBase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventReward" ADD CONSTRAINT "EventReward_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventReward" ADD CONSTRAINT "EventReward_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "EventBase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

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
ALTER TABLE "_EventBaseToRestrictionGroup" ADD CONSTRAINT "_EventBaseToRestrictionGroup_A_fkey" FOREIGN KEY ("A") REFERENCES "EventBase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_EventBaseToRestrictionGroup" ADD CONSTRAINT "_EventBaseToRestrictionGroup_B_fkey" FOREIGN KEY ("B") REFERENCES "RestrictionGroup"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_participant" ADD CONSTRAINT "_participant_A_fkey" FOREIGN KEY ("A") REFERENCES "PrevChallenge"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_participant" ADD CONSTRAINT "_participant_B_fkey" FOREIGN KEY ("B") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
