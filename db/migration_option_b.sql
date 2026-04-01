-- Migration script for existing DB to Option B (NULL passwords) and complaint_code
-- Run statements one by one or as a whole (ensure semicolons).

USE complaint_portal;

-- 1) Allow NULL in users.password so citizens don't need a password
ALTER TABLE users 
  MODIFY password VARCHAR(255) NULL;

-- 2) Optional cleanup: clear any placeholder passwords for citizens
-- Safe-update friendly version (uses PK)
UPDATE users 
SET password = NULL 
WHERE role = 'user' 
  AND user_id > 0 
  AND password IS NOT NULL;

-- 3) Add complaint_code column if not present and ensure unique index
-- If your MySQL doesn't support IF NOT EXISTS, run the plain ADD COLUMN once.
-- ALTER TABLE complaints ADD COLUMN IF NOT EXISTS complaint_code VARCHAR(30);
ALTER TABLE complaints ADD COLUMN complaint_code VARCHAR(30);

-- Create unique index (ignore if duplicate key error occurs)
ALTER TABLE complaints 
  ADD UNIQUE KEY uq_complaint_code (complaint_code);

-- 4) Backfill complaint_code where NULL
UPDATE complaints
SET complaint_code = CONCAT('CMP-', DATE_FORMAT(created_at, '%Y%m%d'), '-', LPAD(complaint_id, 6, '0'))
WHERE complaint_code IS NULL;
