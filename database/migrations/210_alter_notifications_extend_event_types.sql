USE cargoconnect_db;

ALTER TABLE notifications
  DROP CONSTRAINT chk_notifications_type;

ALTER TABLE notifications
  ADD CONSTRAINT chk_notifications_type CHECK (
    notification_type IN (
      'booking_confirmed',
      'shipment_approved',
      'driver_assigned',
      'driver_accepted',
      'driver_rejected',
      'shipment_started',
      'pickup_completed',
      'in_transit',
      'delivered',
      'completed',
      'cancelled',
      'emergency_reported',
      'support_reply',
      'system'
    )
  );
