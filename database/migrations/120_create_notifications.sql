USE cargoconnect_db;

CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  shipment_id BIGINT UNSIGNED NULL,
  notification_type VARCHAR(40) NOT NULL,
  title VARCHAR(140) NOT NULL,
  message TEXT NOT NULL,
  channel VARCHAR(20) NOT NULL DEFAULT 'in_app',
  read_at TIMESTAMP NULL DEFAULT NULL,
  sent_at TIMESTAMP NULL DEFAULT NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_notifications_user_read (user_id, read_at),
  KEY idx_notifications_shipment_id (shipment_id),
  KEY idx_notifications_type (notification_type),
  KEY idx_notifications_created_at (created_at),
  KEY idx_notifications_deleted_at (deleted_at),
  CONSTRAINT fk_notifications_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_notifications_shipment_id FOREIGN KEY (shipment_id) REFERENCES shipments (id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT chk_notifications_type CHECK (notification_type IN ('booking_confirmed', 'driver_assigned', 'shipment_started', 'delivered', 'cancelled', 'support_reply', 'system')),
  CONSTRAINT chk_notifications_channel CHECK (channel IN ('in_app', 'email', 'sms', 'push'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
