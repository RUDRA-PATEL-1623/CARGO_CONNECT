const customerNotificationService = require('../services/customerNotification.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const listNotifications = asyncHandler(async (req, res) => {
  const result = await customerNotificationService.listNotifications(
    req.user.id,
    req.query,
  );

  return successResponse({
    res,
    message: 'Customer notifications fetched successfully.',
    data: result,
  });
});

const markNotificationRead = asyncHandler(async (req, res) => {
  const notification = await customerNotificationService.markNotificationRead(
    req.user.id,
    req.params.notificationId,
  );

  return successResponse({
    res,
    message: 'Notification marked as read successfully.',
    data: {
      notification,
    },
  });
});

const markAllNotificationsRead = asyncHandler(async (req, res) => {
  const result = await customerNotificationService.markAllNotificationsRead(
    req.user.id,
  );

  return successResponse({
    res,
    message: 'All notifications marked as read successfully.',
    data: result,
  });
});

const clearNotifications = asyncHandler(async (req, res) => {
  const result = await customerNotificationService.clearNotifications(
    req.user.id,
  );

  return successResponse({
    res,
    message: 'Notifications cleared successfully.',
    data: result,
  });
});

module.exports = {
  clearNotifications,
  listNotifications,
  markAllNotificationsRead,
  markNotificationRead,
};
