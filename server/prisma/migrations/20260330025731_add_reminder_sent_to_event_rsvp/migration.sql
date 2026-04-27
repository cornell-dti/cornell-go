-- AlterTable
ALTER TABLE "EventRSVP" ADD COLUMN     "reminderSent" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "User" ALTER COLUMN "hasCompletedOnboarding" SET DEFAULT false;
