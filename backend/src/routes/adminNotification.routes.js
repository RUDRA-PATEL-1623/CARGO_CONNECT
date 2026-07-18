const express = require('express');

const notificationController = require('../controllers/notification.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  createNotificationValidator,
  notificationIdParamValidator,
  notificationListValidator,
} = require('../validators/notification.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/notifications
 * @description List notifications for the authenticated admin.
 */
router.get(
  '/notifications',
  notificationListValidator,
  validateRequest,
  notificationController.listNotifications,
);

/**
 * @route POST /api/v1/admin/notifications
 * @description Create an in-app notification for one user or an active role.
 */
router.post(
  '/notifications',
  createNotificationValidator,
  validateRequest,
  notificationController.createNotification,
);

/**
 * @route PATCH /api/v1/admin/notifications/read-all
 * @description Mark all admin notifications as read.
 */
router.patch(
  '/notifications/read-all',
  notificationController.markAllNotificationsRead,
);

/**
 * @route DELETE /api/v1/admin/notifications/clear
 * @description Soft clear all admin notifications.
 */
router.delete(
  '/notifications/clear',
  notificationController.clearNotifications,
);

/**
 * @route PATCH /api/v1/admin/notifications/:notificationId/read
 * @description Mark one admin notification as read.
 */
router.patch(
  '/notifications/:notificationId/read',
  notificationIdParamValidator,
  validateRequest,
  notificationController.markNotificationRead,
);

module.exports = router;
