USE cargoconnect_db;

INSERT INTO shipment_categories (
  code,
  name,
  description,
  suggested_vehicle_type,
  icon_key,
  base_price,
  price_per_km,
  max_weight_kg,
  is_fragile_allowed,
  sort_order
) VALUES
  ('small_parcel', 'Small Parcel', 'Documents, boxes, and lightweight parcels.', 'bike', 'package-small', 149.00, 18.00, 10.00, 1, 1),
  ('medium_goods', 'Medium Goods', 'Retail goods, cartons, and appliance-sized loads.', 'mini_truck', 'boxes', 499.00, 32.00, 250.00, 1, 2),
  ('heavy_cargo', 'Heavy Cargo', 'Industrial and bulk cargo needing higher capacity.', 'heavy_truck', 'container', 1499.00, 58.00, 5000.00, 0, 3),
  ('refrigerated', 'Refrigerated', 'Temperature-sensitive goods and cold-chain loads.', 'refrigerated_truck', 'snowflake', 1299.00, 52.00, 1500.00, 0, 4),
  ('fragile', 'Fragile', 'Glassware, electronics, and careful-handle cargo.', 'van', 'shield-alert', 699.00, 38.00, 500.00, 1, 5),
  ('urgent', 'Urgent', 'Priority pickup and expedited delivery.', 'mini_truck', 'zap', 899.00, 48.00, 300.00, 1, 6)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  description = VALUES(description),
  suggested_vehicle_type = VALUES(suggested_vehicle_type),
  icon_key = VALUES(icon_key),
  base_price = VALUES(base_price),
  price_per_km = VALUES(price_per_km),
  max_weight_kg = VALUES(max_weight_kg),
  is_fragile_allowed = VALUES(is_fragile_allowed),
  sort_order = VALUES(sort_order),
  is_active = 1,
  deleted_at = NULL;
