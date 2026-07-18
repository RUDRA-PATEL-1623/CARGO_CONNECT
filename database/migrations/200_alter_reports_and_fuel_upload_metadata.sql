USE cargoconnect_db;

ALTER TABLE emergency_reports
  ADD COLUMN issue_type VARCHAR(80) NULL AFTER report_type;

ALTER TABLE fuel_requests
  ADD COLUMN bill_file_name VARCHAR(255) NULL AFTER bill_file_url,
  ADD COLUMN bill_file_mime_type VARCHAR(120) NULL AFTER bill_file_name,
  ADD COLUMN bill_file_size_bytes BIGINT UNSIGNED NULL AFTER bill_file_mime_type;
