const notificationService = require('../services/notification.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const listNotifications = asyncHandler(async (req, res) => {
  const result = await notificationService.listUserNotifications(
    req.user.id,
    req.query,
  );

  return successResponse({
    res,
    message: 'Notifications fetched successfully.',
    data: result,
  });
});

const markNotificationRead = asyncHandler(async (req, res) => {
  const notification = await notificationService.markNotificationRead(
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
  const result = await notificationService.markAllNotificationsRead(req.user.id);

  return successResponse({
    res,
    message: 'All notifications marked as read successfully.',
    data: result,
  });
});

const clearNotifications = asyncHandler(async (req, res) => {
  const result = await notificationService.clearNotifications(req.user.id);

  return successResponse({
    res,
    message: 'Notifications cleared successfully.',
    data: result,
  });
});

const createNotification = asyncHandler(async (req, res) => {
  const result = await notificationService.createManualNotification({
    actorUserId: req.user.id,
    payload: req.body,
  });

  return successResponse({
    res,
    statusCode: 201,
    message: 'Notification created successfully.',
    data: result,
  });
});

module.exports = {
  clearNotifications,
  createNotification,
  listNotifications,
  markAllNotificationsRead,
  markNotificationRead,
};
