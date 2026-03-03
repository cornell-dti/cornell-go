/*
  Warnings:

  - Added the required column `originalBasePoints` to the `ChallengeTimer` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "ChallengeTimer" ADD COLUMN     "originalBasePoints" INTEGER NOT NULL;
