const { body, param, query } = require('express-validator');

const { allowedUserRoles } = require('../constants/auth.constants');
const {
  allowedNotificationChannels,
  allowedNotificationTypes,
} = require('../constants/notification.constants');

const notificationListValidator = [
  query('page')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer')
    .toInt(),
  query('limit')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1, max: 50 })
    .withMessage('Limit must be between 1 and 50')
    .toInt(),
  query('notificationType')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedNotificationTypes)
    .withMessage(`Notification type must be one of: ${allowedNotificationTypes.join(', ')}`),
  query('unreadOnly')
    .optional({ nullable: true, checkFalsy: true })
    .isBoolean()
    .withMessage('Unread only must be true or false')
    .toBoolean(),
  query('shipmentId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
];

const notificationIdParamValidator = [
  param('notificationId')
    .isInt({ min: 1 })
    .withMessage('Notification id must be a positive integer')
    .toInt(),
];

const createNotificationValidator = [
  body('userId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('User id must be a positive integer')
    .toInt(),
  body('targetRole')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedUserRoles)
    .withMessage(`Target role must be one of: ${allowedUserRoles.join(', ')}`),
  body()
    .custom((value) => Boolean(value.userId || value.targetRole))
    .withMessage('Either userId or targetRole is required'),
  body('shipmentId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
  body('notificationType')
    .isIn(allowedNotificationTypes)
    .withMessage(`Notification type must be one of: ${allowedNotificationTypes.join(', ')}`),
  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 140 })
    .withMessage('Title must be 140 characters or less'),
  body('message')
    .trim()
    .notEmpty()
    .withMessage('Message is required')
    .isLength({ max: 2000 })
    .withMessage('Message must be 2000 characters or less'),
  body('channel')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedNotificationChannels)
    .withMessage(`Channel must be one of: ${allowedNotificationChannels.join(', ')}`),
  body('metadata')
    .optional({ nullable: true })
    .isObject()
    .withMessage('Metadata must be an object'),
];

module.exports = {
  createNotificationValidator,
  notificationIdParamValidator,
  notificationListValidator,
};
