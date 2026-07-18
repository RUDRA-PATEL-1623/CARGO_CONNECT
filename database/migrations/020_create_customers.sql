USE cargoconnect_db;

CREATE TABLE IF NOT EXISTS customers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  customer_code VARCHAR(40) NOT NULL,
  address_line1 VARCHAR(180) NULL,
  address_line2 VARCHAR(180) NULL,
  city VARCHAR(100) NULL,
  state VARCHAR(100) NULL,
  postal_code VARCHAR(20) NULL,
  country VARCHAR(80) NOT NULL DEFAULT 'India',
  account_status VARCHAR(20) NOT NULL DEFAULT 'active',
  total_shipments INT UNSIGNED NOT NULL DEFAULT 0,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_customers_user_id (user_id),
  UNIQUE KEY uq_customers_customer_code (customer_code),
  KEY idx_customers_account_status (account_status),
  KEY idx_customers_city_state (city, state),
  KEY idx_customers_deleted_at (deleted_at),
  CONSTRAINT fk_customers_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_customers_account_status CHECK (account_status IN ('active', 'inactive', 'blocked'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
