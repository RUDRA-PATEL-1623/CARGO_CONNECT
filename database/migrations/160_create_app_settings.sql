USE cargoconnect_db;

CREATE TABLE IF NOT EXISTS app_settings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  setting_group VARCHAR(80) NOT NULL,
  setting_key VARCHAR(120) NOT NULL,
  setting_value JSON NOT NULL,
  value_type VARCHAR(20) NOT NULL DEFAULT 'json',
  description VARCHAR(255) NULL,
  is_public TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  updated_by_user_id BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_app_settings_group_key (setting_group, setting_key),
  KEY idx_app_settings_group (setting_group),
  KEY idx_app_settings_active_public (is_active, is_public),
  KEY idx_app_settings_updated_by_user_id (updated_by_user_id),
  KEY idx_app_settings_deleted_at (deleted_at),
  CONSTRAINT fk_app_settings_updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES users (id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT chk_app_settings_value_type CHECK (value_type IN ('string', 'number', 'boolean', 'json'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
