-- AlterTable
ALTER TABLE "Challenge" ADD COLUMN     "scheduledEndTime" TIMESTAMP(3),
ADD COLUMN     "scheduledStartTime" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "PrevChallenge" ADD COLUMN     "dateExpired" BOOLEAN NOT NULL DEFAULT false;
