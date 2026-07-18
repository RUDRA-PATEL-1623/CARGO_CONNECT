const { body, param, query } = require('express-validator');

const allowedShipmentStatuses = [
  'pending',
  'approved',
  'assigned',
  'accepted',
  'pickup_completed',
  'in_transit',
  'delivered',
  'completed',
  'cancelled',
  'rejected',
];

const allowedPaymentStatuses = [
  'unpaid',
  'pending',
  'paid',
  'failed',
  'refunded',
  'cancelled',
];

const shipmentIdParamValidator = [
  param('shipmentId')
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
];

const shipmentListValidator = [
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
  query('search')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 120 })
    .withMessage('Search must be 120 characters or less'),
  query('status')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedShipmentStatuses)
    .withMessage(`Status must be one of: ${allowedShipmentStatuses.join(', ')}`),
  query('paymentStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedPaymentStatuses)
    .withMessage(`Payment status must be one of: ${allowedPaymentStatuses.join(', ')}`),
  query('categoryId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Category id must be a positive integer')
    .toInt(),
  query('customerId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Customer id must be a positive integer')
    .toInt(),
  query('assignedDriverId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Assigned driver id must be a positive integer')
    .toInt(),
  query('dateFrom')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Date from must be a valid ISO date'),
  query('dateTo')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Date to must be a valid ISO date')
    .custom((value, { req }) => {
      if (!req.query.dateFrom) {
        return true;
      }

      return new Date(value).getTime() >= new Date(req.query.dateFrom).getTime();
    })
    .withMessage('Date to must be on or after date from'),
];

const approveShipmentValidator = [
  ...shipmentIdParamValidator,
  body('notes')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be 500 characters or less'),
];

const reasonActionValidator = [
  ...shipmentIdParamValidator,
  body('reason')
    .trim()
    .notEmpty()
    .withMessage('Reason is required')
    .isLength({ max: 255 })
    .withMessage('Reason must be 255 characters or less'),
];

const reassignShipmentValidator = [
  ...shipmentIdParamValidator,
  body('driverId')
    .isInt({ min: 1 })
    .withMessage('Driver id must be a positive integer')
    .toInt(),
  body('vehicleId')
    .isInt({ min: 1 })
    .withMessage('Vehicle id must be a positive integer')
    .toInt(),
  body('notes')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be 500 characters or less'),
];

module.exports = {
  approveShipmentValidator,
  reasonActionValidator,
  reassignShipmentValidator,
  shipmentIdParamValidator,
  shipmentListValidator,
};
