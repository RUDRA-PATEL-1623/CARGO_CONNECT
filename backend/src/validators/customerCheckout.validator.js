const { body, param } = require('express-validator');

const allowedPaymentMethods = ['upi', 'card', 'cash', 'wallet', 'bank_transfer'];

const shipmentIdParamValidator = [
  param('shipmentId')
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
];

const invoiceIdParamValidator = [
  param('invoiceId')
    .isInt({ min: 1 })
    .withMessage('Invoice id must be a positive integer')
    .toInt(),
];

const mockPaymentConfirmValidator = [
  ...shipmentIdParamValidator,
  body('paymentMethod')
    .isIn(allowedPaymentMethods)
    .withMessage(`Payment method must be one of: ${allowedPaymentMethods.join(', ')}`),
  body('acceptTerms')
    .custom((value) => value === true || value === 'true')
    .withMessage('Terms must be accepted')
    .toBoolean(),
  body('couponCode')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 40 })
    .withMessage('Coupon code must be 2-40 characters')
    .matches(/^[A-Z0-9_-]+$/i)
    .withMessage('Coupon code can include letters, numbers, underscores, and dashes'),
];

module.exports = {
  invoiceIdParamValidator,
  mockPaymentConfirmValidator,
  shipmentIdParamValidator,
};
