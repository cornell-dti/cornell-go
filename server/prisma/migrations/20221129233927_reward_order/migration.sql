/*
  Warnings:

  - Added the required column `eventIndex` to the `EventReward` table without a default value. This is not possible if the table is not empty.

*/
-- DropIndex
DROP INDEX "EventBase_isDefault_key";

-- AlterTable
ALTER TABLE "EventReward" ADD COLUMN     "eventIndex" INTEGER NOT NULL;
