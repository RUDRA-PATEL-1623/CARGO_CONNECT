USE cargoconnect_db;

INSERT INTO app_settings (
  setting_group,
  setting_key,
  setting_value,
  value_type,
  description,
  is_public,
  is_active,
  updated_by_user_id
)
VALUES
(
  'status_master',
  'shipment_status_flow',
  '["pending","approved","assigned","accepted","pickup_completed","in_transit","delivered","completed"]',
  'json',
  'Canonical shipment status flow enforced by the backend.',
  0,
  1,
  (SELECT id FROM users WHERE username = 'admin' LIMIT 1)
),
(
  'notification_settings',
  'notify_customer_on_status_change',
  'true',
  'boolean',
  'Send in-app customer notification on shipment status changes.',
  0,
  1,
  (SELECT id FROM users WHERE username = 'admin' LIMIT 1)
),
(
  'app_settings',
  'support_email',
  '"support@cargoconnect.local"',
  'string',
  'Admin support mailbox shown in local testing flows.',
  1,
  1,
  (SELECT id FROM users WHERE username = 'admin' LIMIT 1)
),
(
  'business_rules',
  'tax_percent',
  '18',
  'number',
  'Default tax percentage for local price estimates.',
  0,
  1,
  (SELECT id FROM users WHERE username = 'admin' LIMIT 1)
)
ON DUPLICATE KEY UPDATE
  setting_value = VALUES(setting_value),
  value_type = VALUES(value_type),
  description = VALUES(description),
  is_public = VALUES(is_public),
  is_active = VALUES(is_active),
  updated_by_user_id = VALUES(updated_by_user_id),
  deleted_at = NULL;
