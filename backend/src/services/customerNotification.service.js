const notificationService = require('./notification.service');

module.exports = {
  clearNotifications: notificationService.clearNotifications,
  listNotifications: notificationService.listUserNotifications,
  markAllNotificationsRead: notificationService.markAllNotificationsRead,
  markNotificationRead: notificationService.markNotificationRead,
};
