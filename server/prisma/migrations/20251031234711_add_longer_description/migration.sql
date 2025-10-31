/*
  Warnings:

  - A unique constraint covering the columns `[username]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `longDescription` to the `EventBase` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "EventBase" ADD COLUMN     "longDescription" TEXT NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");
