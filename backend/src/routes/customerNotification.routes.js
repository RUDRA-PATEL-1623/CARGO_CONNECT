const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const customerNotificationController = require('../controllers/customerNotification.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  notificationIdParamValidator,
  notificationListValidator,
} = require('../validators/customerNotification.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.CUSTOMER));

/**
 * @route GET /api/v1/customer/notifications
 * @description List customer notifications with read/type filters.
 */
router.get(
  '/notifications',
  notificationListValidator,
  validateRequest,
  customerNotificationController.listNotifications,
);

/**
 * @route PATCH /api/v1/customer/notifications/read-all
 * @description Mark all customer notifications as read.
 */
router.patch(
  '/notifications/read-all',
  customerNotificationController.markAllNotificationsRead,
);

/**
 * @route DELETE /api/v1/customer/notifications/clear
 * @description Soft clear all customer notifications.
 */
router.delete(
  '/notifications/clear',
  customerNotificationController.clearNotifications,
);

/**
 * @route PATCH /api/v1/customer/notifications/:notificationId/read
 * @description Mark a customer notification as read.
 */
router.patch(
  '/notifications/:notificationId/read',
  notificationIdParamValidator,
  validateRequest,
  customerNotificationController.markNotificationRead,
);

module.exports = router;
