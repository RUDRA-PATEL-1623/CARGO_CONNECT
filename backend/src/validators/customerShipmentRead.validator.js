const { param, query } = require('express-validator');

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

const allowedProofTypes = ['pickup', 'delivery', 'damage', 'invoice', 'other'];

const paginationValidator = [
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
];

const shipmentIdParamValidator = [
  param('shipmentId')
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
];

const proofIdParamValidator = [
  param('proofId')
    .isInt({ min: 1 })
    .withMessage('Proof id must be a positive integer')
    .toInt(),
];

const shipmentHistoryValidator = [
  ...paginationValidator,
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
  query('categoryCode')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 40 })
    .withMessage('Category code must be 2-40 characters'),
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

const proofListValidator = [
  ...shipmentIdParamValidator,
  query('proofType')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedProofTypes)
    .withMessage(`Proof type must be one of: ${allowedProofTypes.join(', ')}`),
];

const proofDetailValidator = [
  ...shipmentIdParamValidator,
  ...proofIdParamValidator,
];

module.exports = {
  proofDetailValidator,
  proofListValidator,
  shipmentHistoryValidator,
  shipmentIdParamValidator,
};
