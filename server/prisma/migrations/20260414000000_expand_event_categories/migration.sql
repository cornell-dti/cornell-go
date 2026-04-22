-- Remap existing categories before altering the enum
UPDATE "EventBase" SET "category" = 'FOOD' WHERE "category" = 'CAFE';
UPDATE "EventBase" SET "category" = 'FOOD' WHERE "category" = 'DININGHALL';
UPDATE "EventBase" SET "category" = 'DORM' WHERE "category" = 'DORM';

-- Create new enum type with updated values
CREATE TYPE "EventCategoryType_new" AS ENUM ('FOOD', 'NATURE', 'HISTORICAL', 'RESIDENTIAL', 'LANDMARK', 'ARTS', 'ATHLETICS', 'LIBRARY', 'ACADEMIC', 'RECREATION');

-- Remap DORM to RESIDENTIAL during the column type change
ALTER TABLE "EventBase"
  ALTER COLUMN "category" TYPE "EventCategoryType_new"
  USING (
    CASE "category"::text
      WHEN 'DORM' THEN 'RESIDENTIAL'::"EventCategoryType_new"
      ELSE "category"::text::"EventCategoryType_new"
    END
  );

-- Drop old enum and rename new one
DROP TYPE "EventCategoryType";
ALTER TYPE "EventCategoryType_new" RENAME TO "EventCategoryType";
