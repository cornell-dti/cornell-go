-- AlterTable
ALTER TABLE "EventBase" ADD COLUMN     "isJourney" BOOLEAN NOT NULL DEFAULT false;

-- Backfill: set isJourney = true for events with more than 1 challenge
UPDATE "EventBase" SET "isJourney" = true WHERE (SELECT COUNT(*) FROM "Challenge" WHERE "linkedEventId" = "EventBase"."id") > 1;

-- AlterTable
ALTER TABLE "User" ALTER COLUMN "hasCompletedOnboarding" DROP DEFAULT;
