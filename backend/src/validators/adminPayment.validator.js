const { param, query } = require('express-validator');

const paymentStatuses = ['pending', 'paid', 'failed', 'refunded', 'cancelled'];
const paymentMethods = ['upi', 'card', 'cash', 'wallet', 'bank_transfer'];

const paymentIdParamValidator = [
  param('paymentId')
    .isInt({ min: 1 })
    .withMessage('Payment id must be a positive integer')
    .toInt(),
];

const paymentListValidator = [
  query('page')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer')
    .toInt(),
  query('limit')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100')
    .toInt(),
  query('search')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 120 })
    .withMessage('Search must be 120 characters or less'),
  query('status')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(paymentStatuses)
    .withMessage(`Payment status must be one of: ${paymentStatuses.join(', ')}`),
  query('paymentStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(paymentStatuses)
    .withMessage(`Payment status must be one of: ${paymentStatuses.join(', ')}`),
  query('paymentMethod')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(paymentMethods)
    .withMessage(`Payment method must be one of: ${paymentMethods.join(', ')}`),
  query('categoryId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Category id must be a positive integer')
    .toInt(),
  query('categoryCode')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 40 })
    .withMessage('Category code must be 40 characters or less'),
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

module.exports = {
  paymentIdParamValidator,
  paymentListValidator,
};
