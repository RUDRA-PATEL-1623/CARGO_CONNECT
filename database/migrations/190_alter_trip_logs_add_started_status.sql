USE cargoconnect_db;

ALTER TABLE trip_logs
  DROP CONSTRAINT chk_trip_logs_status;

ALTER TABLE trip_logs
  ADD CONSTRAINT chk_trip_logs_status CHECK (
    status IN (
      'pending',
      'approved',
      'assigned',
      'accepted',
      'started',
      'pickup_completed',
      'in_transit',
      'delivered',
      'completed',
      'cancelled',
      'delayed',
      'issue_reported'
    )
  );