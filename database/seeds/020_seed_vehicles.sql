USE cargoconnect_db;

INSERT INTO vehicles (
  vehicle_number,
  registration_number,
  vehicle_type,
  model,
  capacity_kg,
  fuel_type,
  insurance_expiry_date,
  service_due_date,
  availability_status,
  assigned_driver_id
) VALUES
  ('CC-TEST-0001', 'MH12CC9999', 'mini_truck', 'Tata Ace EV', 750.00, 'electric', '2028-12-31', '2026-10-01', 'assigned', (SELECT id FROM drivers WHERE driver_code = 'DRV-TEST')),
  ('CC-MH-1001', 'MH12AB1234', 'mini_truck', 'Tata Ace Gold', 750.00, 'diesel', '2027-04-30', '2026-08-15', 'available', (SELECT id FROM drivers WHERE driver_code = 'DRV-0001')),
  ('CC-KA-2001', 'KA05CD5678', 'truck', 'Ashok Leyland Dost', 1500.00, 'diesel', '2027-06-12', '2026-07-01', 'assigned', (SELECT id FROM drivers WHERE driver_code = 'DRV-0002')),
  ('CC-DL-3001', 'DL08EF9012', 'refrigerated_truck', 'Mahindra Supro Reefer', 1200.00, 'diesel', '2028-01-10', '2026-09-20', 'available', (SELECT id FROM drivers WHERE driver_code = 'DRV-0003'))
ON DUPLICATE KEY UPDATE
  registration_number = VALUES(registration_number),
  vehicle_type = VALUES(vehicle_type),
  model = VALUES(model),
  capacity_kg = VALUES(capacity_kg),
  fuel_type = VALUES(fuel_type),
  insurance_expiry_date = VALUES(insurance_expiry_date),
  service_due_date = VALUES(service_due_date),
  availability_status = VALUES(availability_status),
  assigned_driver_id = VALUES(assigned_driver_id),
  deleted_at = NULL;
