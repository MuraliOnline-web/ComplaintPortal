-- Archive tables for solved complaints history (MySQL)
-- Run this once to create archive tables mirroring current tables.

USE complaint_portal;

CREATE TABLE IF NOT EXISTS complaints_archive LIKE complaints;
-- Ensure complaint_code remains unique across both tables independently
ALTER TABLE complaints_archive
  DROP INDEX complaint_code,
  ADD UNIQUE KEY uq_complaint_code_archive (complaint_code);

CREATE TABLE IF NOT EXISTS notifications_archive LIKE notifications;

-- Optional helper indexes
CREATE INDEX idx_comp_archive_created ON complaints_archive(created_at);
CREATE INDEX idx_comp_archive_status ON complaints_archive(status);
CREATE INDEX idx_notif_archive_compid ON notifications_archive(complaint_id);
