const { body, param } = require('express-validator');

const allowedVehiclePreferences = [
  'bike',
  'mini_truck',
  'truck',
  'heavy_truck',
  'refrigerated_truck',
  'van',
];

const allowedPaymentMethods = ['upi', 'card', 'cash', 'wallet', 'bank_transfer'];

const categorySelectorValidator = [
  body('categoryId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Category id must be a positive integer')
    .toInt(),
  body('categoryCode')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 40 })
    .withMessage('Category code must be 2-40 characters'),
  body()
    .custom((value) => Boolean(value.categoryId || value.categoryCode))
    .withMessage('Category id or category code is required'),
];

const packagePricingFields = [
  body('packageWeightKg')
    .isFloat({ gt: 0 })
    .withMessage('Package weight must be greater than 0')
    .toFloat(),
  body('estimatedDistanceKm')
    .optional({ nullable: true, checkFalsy: true })
    .isFloat({ min: 0 })
    .withMessage('Estimated distance must be 0 or greater')
    .toFloat(),
  body('isFragile')
    .optional()
    .isBoolean()
    .withMessage('Fragile must be true or false')
    .toBoolean(),
];

const shipmentFormFields = [
  body('pickupAddress')
    .trim()
    .notEmpty()
    .withMessage('Pickup address is required')
    .isLength({ max: 1000 })
    .withMessage('Pickup address must be 1000 characters or less'),
  body('deliveryAddress')
    .trim()
    .notEmpty()
    .withMessage('Delivery address is required')
    .isLength({ max: 1000 })
    .withMessage('Delivery address must be 1000 characters or less'),
  body('pickupCity')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('Pickup city must be 100 characters or less'),
  body('pickupState')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('Pickup state must be 100 characters or less'),
  body('pickupPostalCode')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 20 })
    .withMessage('Pickup postal code must be 20 characters or less'),
  body('deliveryCity')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('Delivery city must be 100 characters or less'),
  body('deliveryState')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('Delivery state must be 100 characters or less'),
  body('deliveryPostalCode')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 20 })
    .withMessage('Delivery postal code must be 20 characters or less'),
  body('packageType')
    .trim()
    .notEmpty()
    .withMessage('Package type is required')
    .isLength({ max: 80 })
    .withMessage('Package type must be 80 characters or less'),
  body('dimensions')
    .optional({ nullable: true })
    .isObject()
    .withMessage('Dimensions must be an object'),
  body('dimensions.lengthCm')
    .optional({ nullable: true, checkFalsy: true })
    .isFloat({ gt: 0 })
    .withMessage('Length must be greater than 0')
    .toFloat(),
  body('dimensions.widthCm')
    .optional({ nullable: true, checkFalsy: true })
    .isFloat({ gt: 0 })
    .withMessage('Width must be greater than 0')
    .toFloat(),
  body('dimensions.heightCm')
    .optional({ nullable: true, checkFalsy: true })
    .isFloat({ gt: 0 })
    .withMessage('Height must be greater than 0')
    .toFloat(),
  body('vehiclePreference')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedVehiclePreferences)
    .withMessage(`Vehicle preference must be one of: ${allowedVehiclePreferences.join(', ')}`),
  body('pickupDateTime')
    .isISO8601()
    .withMessage('Pickup date/time must be a valid ISO date')
    .custom((value) => new Date(value).getTime() > Date.now())
    .withMessage('Pickup date/time must be in the future'),
  body('receiverName')
    .trim()
    .notEmpty()
    .withMessage('Receiver name is required')
    .isLength({ max: 120 })
    .withMessage('Receiver name must be 120 characters or less'),
  body('receiverPhone')
    .trim()
    .notEmpty()
    .withMessage('Receiver phone is required')
    .isLength({ min: 7, max: 30 })
    .withMessage('Receiver phone must be 7-30 characters')
    .matches(/^\+?[0-9\s-]+$/)
    .withMessage('Receiver phone can include digits, spaces, dashes, and leading plus'),
  body('deliveryNotes')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Delivery notes must be 1000 characters or less'),
];

const estimateValidator = [
  ...categorySelectorValidator,
  ...packagePricingFields,
];

const createShipmentValidator = [
  ...categorySelectorValidator,
  ...packagePricingFields,
  ...shipmentFormFields,
];

const shipmentIdParamValidator = [
  param('shipmentId')
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
];

const placeOrderValidator = [
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
  createShipmentValidator,
  estimateValidator,
  placeOrderValidator,
  shipmentIdParamValidator,
};
