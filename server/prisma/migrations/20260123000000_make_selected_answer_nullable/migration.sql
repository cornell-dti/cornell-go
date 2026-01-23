-- Make selectedAnswerId nullable and add SetNull on delete
ALTER TABLE "UserQuizAnswer" DROP CONSTRAINT IF EXISTS "UserQuizAnswer_selectedAnswerId_fkey";

ALTER TABLE "UserQuizAnswer" ALTER COLUMN "selectedAnswerId" DROP NOT NULL;

ALTER TABLE "UserQuizAnswer" ADD CONSTRAINT "UserQuizAnswer_selectedAnswerId_fkey"
  FOREIGN KEY ("selectedAnswerId") REFERENCES "QuizAnswer"("id") ON DELETE SET NULL ON UPDATE CASCADE;
