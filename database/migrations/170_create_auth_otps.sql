USE cargoconnect_db;

CREATE TABLE IF NOT EXISTS auth_otps (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NULL,
  destination VARCHAR(160) NOT NULL,
  purpose VARCHAR(30) NOT NULL,
  otp_hash VARCHAR(255) NOT NULL,
  attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
  max_attempts TINYINT UNSIGNED NOT NULL DEFAULT 5,
  expires_at DATETIME NOT NULL,
  consumed_at TIMESTAMP NULL DEFAULT NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_auth_otps_user_purpose (user_id, purpose),
  KEY idx_auth_otps_destination_purpose (destination, purpose),
  KEY idx_auth_otps_expires_at (expires_at),
  KEY idx_auth_otps_consumed_at (consumed_at),
  KEY idx_auth_otps_deleted_at (deleted_at),
  CONSTRAINT fk_auth_otps_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_auth_otps_purpose CHECK (purpose IN ('register', 'login', 'forgot_password', 'reset_password', 'change_password')),
  CONSTRAINT chk_auth_otps_attempts CHECK (attempts <= max_attempts),
  CONSTRAINT chk_auth_otps_max_attempts CHECK (max_attempts > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
