-- AlterTable: Change category from EventCategoryType enum to String
ALTER TABLE "QuizQuestion" ALTER COLUMN "category" TYPE TEXT USING "category"::TEXT;
ALTER TABLE "QuizQuestion" ALTER COLUMN "category" SET DEFAULT 'HISTORICAL';
