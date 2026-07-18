const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const notificationController = require('../controllers/notification.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  notificationIdParamValidator,
  notificationListValidator,
} = require('../validators/notification.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.DRIVER));

/**
 * @route GET /api/v1/driver/notifications
 * @description List notifications for the authenticated driver.
 */
router.get(
  '/notifications',
  notificationListValidator,
  validateRequest,
  notificationController.listNotifications,
);

/**
 * @route PATCH /api/v1/driver/notifications/read-all
 * @description Mark all driver notifications as read.
 */
router.patch(
  '/notifications/read-all',
  notificationController.markAllNotificationsRead,
);

/**
 * @route DELETE /api/v1/driver/notifications/clear
 * @description Soft clear all driver notifications.
 */
router.delete(
  '/notifications/clear',
  notificationController.clearNotifications,
);

/**
 * @route PATCH /api/v1/driver/notifications/:notificationId/read
 * @description Mark one driver notification as read.
 */
router.patch(
  '/notifications/:notificationId/read',
  notificationIdParamValidator,
  validateRequest,
  notificationController.markNotificationRead,
);

module.exports = router;
