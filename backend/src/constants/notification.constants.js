const NOTIFICATION_TYPES = Object.freeze({
  BOOKING_CONFIRMED: 'booking_confirmed',
  SHIPMENT_APPROVED: 'shipment_approved',
  DRIVER_ASSIGNED: 'driver_assigned',
  DRIVER_ACCEPTED: 'driver_accepted',
  DRIVER_REJECTED: 'driver_rejected',
  SHIPMENT_STARTED: 'shipment_started',
  PICKUP_COMPLETED: 'pickup_completed',
  IN_TRANSIT: 'in_transit',
  DELIVERED: 'delivered',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
  EMERGENCY_REPORTED: 'emergency_reported',
  SUPPORT_REPLY: 'support_reply',
  SYSTEM: 'system',
});

const NOTIFICATION_CHANNELS = Object.freeze({
  IN_APP: 'in_app',
  EMAIL: 'email',
  SMS: 'sms',
  PUSH: 'push',
});

module.exports = {
  NOTIFICATION_CHANNELS,
  NOTIFICATION_TYPES,
  allowedNotificationChannels: Object.values(NOTIFICATION_CHANNELS),
  allowedNotificationTypes: Object.values(NOTIFICATION_TYPES),
};
