-- CreateIndex
CREATE UNIQUE INDEX "Feedback_userId_challengeId_key" ON "Feedback"("userId", "challengeId");
