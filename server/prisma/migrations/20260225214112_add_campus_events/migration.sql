-- CreateEnum
CREATE TYPE "CampusEventCategory" AS ENUM ('SOCIAL', 'CULTURAL', 'ATHLETIC', 'WELLNESS', 'ACADEMIC', 'ARTS', 'CAREER', 'COMMUNITY', 'OTHER');

-- CreateEnum
CREATE TYPE "EventSource" AS ENUM ('API_EVENTS', 'ADMIN_CREATED', 'COMMUNITY_SUBMITTED');

-- CreateEnum
CREATE TYPE "ApprovalStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "CheckInMethod" AS ENUM ('LOCATION', 'QR_CODE', 'EITHER');

-- CreateTable
CREATE TABLE "CampusEvent" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "imageUrl" TEXT,
    "startTime" TIMESTAMP(3) NOT NULL,
    "endTime" TIMESTAMP(3) NOT NULL,
    "allDay" BOOLEAN NOT NULL DEFAULT false,
    "locationName" TEXT NOT NULL,
    "address" TEXT,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "checkInRadius" DOUBLE PRECISION NOT NULL DEFAULT 100,
    "categories" "CampusEventCategory"[],
    "tags" TEXT[],
    "source" "EventSource" NOT NULL,
    "externalId" TEXT,
    "externalUrl" TEXT,
    "approvalStatus" "ApprovalStatus" NOT NULL,
    "rejectionReason" TEXT,
    "organizerName" TEXT,
    "organizerEmail" TEXT,
    "organizerId" TEXT,
    "checkInMethod" "CheckInMethod" NOT NULL DEFAULT 'EITHER',
    "qrCode" TEXT,
    "pointsForAttendance" INTEGER NOT NULL DEFAULT 10,
    "featured" BOOLEAN NOT NULL DEFAULT false,
    "registrationUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CampusEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventAttendance" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "campusEventId" TEXT NOT NULL,
    "checkedInAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "checkInMethod" "CheckInMethod" NOT NULL,
    "pointsAwarded" INTEGER NOT NULL,

    CONSTRAINT "EventAttendance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventRSVP" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "campusEventId" TEXT NOT NULL,
    "rsvpAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EventRSVP_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CampusEvent_externalId_key" ON "CampusEvent"("externalId");

-- CreateIndex
CREATE UNIQUE INDEX "CampusEvent_qrCode_key" ON "CampusEvent"("qrCode");

-- CreateIndex
CREATE INDEX "CampusEvent_startTime_idx" ON "CampusEvent"("startTime");

-- CreateIndex
CREATE INDEX "CampusEvent_approvalStatus_idx" ON "CampusEvent"("approvalStatus");

-- CreateIndex
CREATE INDEX "CampusEvent_source_idx" ON "CampusEvent"("source");

-- CreateIndex
CREATE UNIQUE INDEX "EventAttendance_userId_campusEventId_key" ON "EventAttendance"("userId", "campusEventId");

-- CreateIndex
CREATE UNIQUE INDEX "EventRSVP_userId_campusEventId_key" ON "EventRSVP"("userId", "campusEventId");

-- AddForeignKey
ALTER TABLE "CampusEvent" ADD CONSTRAINT "CampusEvent_organizerId_fkey" FOREIGN KEY ("organizerId") REFERENCES "Organization"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventAttendance" ADD CONSTRAINT "EventAttendance_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventAttendance" ADD CONSTRAINT "EventAttendance_campusEventId_fkey" FOREIGN KEY ("campusEventId") REFERENCES "CampusEvent"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventRSVP" ADD CONSTRAINT "EventRSVP_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventRSVP" ADD CONSTRAINT "EventRSVP_campusEventId_fkey" FOREIGN KEY ("campusEventId") REFERENCES "CampusEvent"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
