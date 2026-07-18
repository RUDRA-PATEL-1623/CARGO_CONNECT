USE cargoconnect_db;

ALTER TABLE shipment_categories
  ADD COLUMN icon_key VARCHAR(80) NULL AFTER suggested_vehicle_type;
