USE cargoconnect_db;

CREATE TABLE IF NOT EXISTS shipment_categories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(40) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255) NULL,
  suggested_vehicle_type VARCHAR(30) NULL,
  base_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  price_per_km DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  max_weight_kg DECIMAL(10,2) NULL,
  is_fragile_allowed TINYINT(1) NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  sort_order INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_shipment_categories_code (code),
  KEY idx_shipment_categories_active_sort (is_active, sort_order),
  KEY idx_shipment_categories_deleted_at (deleted_at),
  CONSTRAINT chk_shipment_categories_vehicle_type CHECK (suggested_vehicle_type IS NULL OR suggested_vehicle_type IN ('bike', 'mini_truck', 'truck', 'heavy_truck', 'refrigerated_truck', 'van')),
  CONSTRAINT chk_shipment_categories_base_price CHECK (base_price >= 0),
  CONSTRAINT chk_shipment_categories_price_per_km CHECK (price_per_km >= 0),
  CONSTRAINT chk_shipment_categories_max_weight CHECK (max_weight_kg IS NULL OR max_weight_kg > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
