USE cargoconnect_db;

SET @admin_password_hash = '$2b$10$4wZA/4u2znfq3kjYgmmUbuy95Ym1vbW9qWYTBG2B3phF/yis05ITm';
SET @sample_password_hash = '$2b$10$4wZA/4u2znfq3kjYgmmUbuy95Ym1vbW9qWYTBG2B3phF/yis05ITm';

INSERT INTO users (
  public_id,
  role,
  name,
  username,
  email,
  phone,
  password_hash,
  status,
  email_verified_at,
  phone_verified_at
) VALUES
  ('00000000-0000-4000-8000-000000000001', 'admin', 'CargoConnect Admin', 'admin', 'admin@cargoconnect.local', '+919900000001', @admin_password_hash, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('00000000-0000-4000-8000-000000000002', 'dispatcher', 'CargoConnect Dispatcher', 'dispatcher', 'dispatcher@cargoconnect.local', '+919900000002', @sample_password_hash, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('00000000-0000-4000-8000-000000000100', 'customer', 'CargoConnect Customer', 'customer', 'customer@cargoconnect.local', '+919900000100', @sample_password_hash, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('00000000-0000-4000-8000-000000000101', 'customer', 'Aarav Mehta', 'aarav.customer', 'aarav.mehta@example.com', '+919900000101', @sample_password_hash, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('00000000-0000-4000-8000-000000000102', 'customer', 'Priya Nair', 'priya.customer', 'priya.nair@example.com', '+919900000102', @sample_password_hash, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('00000000-0000-4000-8000-000000000103', 'customer', 'Rohan Kapoor', 'rohan.customer', 'rohan.kapoor@example.com', '+919900000103', @sample_password_hash, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('00000000-0000-4000-8000-000000000200', 'driver', 'CargoConnect Driver', 'driver', 'driver@cargoconnect.local', '+919900000200', @sample_password_hash, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('00000000-0000-4000-8000-000000000201', 'driver', 'Vikram Singh', 'vikram.driver', 'vikram.singh@example.com', '+919900000201', @sample_password_hash, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('00000000-0000-4000-8000-000000000202', 'driver', 'Imran Khan', 'imran.driver', 'imran.khan@example.com', '+919900000202', @sample_password_hash, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('00000000-0000-4000-8000-000000000203', 'driver', 'Neha Sharma', 'neha.driver', 'neha.sharma@example.com', '+919900000203', @sample_password_hash, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON DUPLICATE KEY UPDATE
  role = VALUES(role),
  name = VALUES(name),
  email = VALUES(email),
  phone = VALUES(phone),
  password_hash = VALUES(password_hash),
  status = 'active',
  email_verified_at = COALESCE(email_verified_at, CURRENT_TIMESTAMP),
  phone_verified_at = COALESCE(phone_verified_at, CURRENT_TIMESTAMP),
  deleted_at = NULL;

INSERT INTO customers (
  user_id,
  customer_code,
  address_line1,
  address_line2,
  city,
  state,
  postal_code,
  account_status,
  total_shipments
) VALUES
  ((SELECT id FROM users WHERE username = 'customer'), 'CUST-TEST', 'CargoConnect Test Customer Address', 'Local Test Area', 'Mumbai', 'Maharashtra', '400001', 'active', 1),
  ((SELECT id FROM users WHERE username = 'aarav.customer'), 'CUST-0001', 'Bandra Kurla Complex', 'Bandra East', 'Mumbai', 'Maharashtra', '400051', 'active', 2),
  ((SELECT id FROM users WHERE username = 'priya.customer'), 'CUST-0002', 'Indiranagar 100 Feet Road', 'Stage 2', 'Bengaluru', 'Karnataka', '560038', 'active', 2),
  ((SELECT id FROM users WHERE username = 'rohan.customer'), 'CUST-0003', 'Connaught Place', 'Block A', 'New Delhi', 'Delhi', '110001', 'active', 1)
ON DUPLICATE KEY UPDATE
  address_line1 = VALUES(address_line1),
  address_line2 = VALUES(address_line2),
  city = VALUES(city),
  state = VALUES(state),
  postal_code = VALUES(postal_code),
  account_status = VALUES(account_status),
  total_shipments = VALUES(total_shipments),
  deleted_at = NULL;

INSERT INTO drivers (
  user_id,
  driver_code,
  license_number,
  license_expiry_date,
  address_line1,
  city,
  state,
  postal_code,
  availability_status,
  driver_status,
  rating,
  completed_trips
) VALUES
  ((SELECT id FROM users WHERE username = 'driver'), 'DRV-TEST', 'MH12CC2026999', '2028-12-31', 'CargoConnect Driver Address', 'Mumbai', 'Maharashtra', '400001', 'busy', 'active', 4.70, 42),
  ((SELECT id FROM users WHERE username = 'vikram.driver'), 'DRV-0001', 'MH12CC2026001', '2028-07-15', 'Andheri East', 'Mumbai', 'Maharashtra', '400069', 'available', 'active', 4.80, 124),
  ((SELECT id FROM users WHERE username = 'imran.driver'), 'DRV-0002', 'KA05CC2026002', '2027-11-20', 'Whitefield', 'Bengaluru', 'Karnataka', '560066', 'busy', 'active', 4.60, 98),
  ((SELECT id FROM users WHERE username = 'neha.driver'), 'DRV-0003', 'DL08CC2026003', '2029-02-10', 'Dwarka Sector 10', 'New Delhi', 'Delhi', '110075', 'available', 'active', 4.90, 142)
ON DUPLICATE KEY UPDATE
  license_number = VALUES(license_number),
  license_expiry_date = VALUES(license_expiry_date),
  address_line1 = VALUES(address_line1),
  city = VALUES(city),
  state = VALUES(state),
  postal_code = VALUES(postal_code),
  availability_status = VALUES(availability_status),
  driver_status = VALUES(driver_status),
  rating = VALUES(rating),
  completed_trips = VALUES(completed_trips),
  deleted_at = NULL;
