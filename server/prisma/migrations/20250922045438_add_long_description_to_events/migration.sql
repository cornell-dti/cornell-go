/*
  Warnings:

  - A unique constraint covering the columns `[username]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `longDescription` to the `EventBase` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable (skip if column already exists)
ALTER TABLE "EventBase" ADD COLUMN IF NOT EXISTS "longDescription" TEXT NOT NULL DEFAULT '';

-- CreateIndex (skip if already exists)
CREATE UNIQUE INDEX IF NOT EXISTS "User_username_key" ON "User"("username");