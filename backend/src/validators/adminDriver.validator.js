const { body, param, query } = require('express-validator');

const { PASSWORD_RULES } = require('../constants/auth.constants');

const allowedAvailabilityStatuses = ['available', 'busy', 'offline', 'on_leave'];
const allowedDriverStatuses = ['active', 'inactive', 'suspended'];

const passwordValidator = (field = 'password') => {
  return body(field)
    .optional({ nullable: true, checkFalsy: true })
    .isLength({
      min: PASSWORD_RULES.minLength,
      max: PASSWORD_RULES.maxLength,
    })
    .withMessage(
      `Password must be ${PASSWORD_RULES.minLength}-${PASSWORD_RULES.maxLength} characters`,
    )
    .matches(/[a-z]/)
    .withMessage('Password must include a lowercase letter')
    .matches(/[A-Z]/)
    .withMessage('Password must include an uppercase letter')
    .matches(/[0-9]/)
    .withMessage('Password must include a number')
    .matches(/[^A-Za-z0-9]/)
    .withMessage('Password must include a special character');
};

const driverIdParamValidator = [
  param('driverId')
    .isInt({ min: 1 })
    .withMessage('Driver id must be a positive integer')
    .toInt(),
];

const baseDriverFields = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Driver name is required')
    .isLength({ min: 2, max: 120 })
    .withMessage('Driver name must be 2-120 characters'),
  body('username')
    .trim()
    .notEmpty()
    .withMessage('Username is required')
    .isLength({ min: 3, max: 80 })
    .withMessage('Username must be 3-80 characters')
    .matches(/^[A-Za-z0-9._-]+$/)
    .withMessage('Username can only contain letters, numbers, dots, dashes, and underscores'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Valid email is required')
    .normalizeEmail(),
  body('phone')
    .trim()
    .notEmpty()
    .withMessage('Phone is required')
    .isLength({ min: 7, max: 30 })
    .withMessage('Phone must be 7-30 characters')
    .matches(/^\+?[0-9\s-]+$/)
    .withMessage('Phone can include digits, spaces, dashes, and leading plus'),
  body('licenseNumber')
    .trim()
    .notEmpty()
    .withMessage('License number is required')
    .isLength({ min: 4, max: 80 })
    .withMessage('License number must be 4-80 characters'),
  body('licenseExpiryDate')
    .isISO8601()
    .withMessage('License expiry date must be a valid date')
    .custom((value) => new Date(value).getTime() > Date.now())
    .withMessage('License expiry date must be in the future'),
  body('addressLine1')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 180 })
    .withMessage('Address line 1 must be 180 characters or less'),
  body('address')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 180 })
    .withMessage('Address must be 180 characters or less'),
  body('addressLine2')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 180 })
    .withMessage('Address line 2 must be 180 characters or less'),
  body('city')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('City must be 100 characters or less'),
  body('state')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('State must be 100 characters or less'),
  body('postalCode')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 20 })
    .withMessage('Postal code must be 20 characters or less'),
  body('availabilityStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedAvailabilityStatuses)
    .withMessage(`Availability status must be one of: ${allowedAvailabilityStatuses.join(', ')}`),
  body('driverStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedDriverStatuses)
    .withMessage(`Driver status must be one of: ${allowedDriverStatuses.join(', ')}`),
  body('emergencyContactName')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 120 })
    .withMessage('Emergency contact name must be 120 characters or less'),
  body('emergencyContactPhone')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 7, max: 30 })
    .withMessage('Emergency contact phone must be 7-30 characters')
    .matches(/^\+?[0-9\s-]+$/)
    .withMessage('Emergency contact phone can include digits, spaces, dashes, and leading plus'),
];

const createDriverValidator = [
  ...baseDriverFields,
  passwordValidator('password'),
];

const optionalDriverFields = [
  body('name')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 120 })
    .withMessage('Driver name must be 2-120 characters'),
  body('username')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 3, max: 80 })
    .withMessage('Username must be 3-80 characters')
    .matches(/^[A-Za-z0-9._-]+$/)
    .withMessage('Username can only contain letters, numbers, dots, dashes, and underscores'),
  body('email')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isEmail()
    .withMessage('Valid email is required')
    .normalizeEmail(),
  body('phone')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 7, max: 30 })
    .withMessage('Phone must be 7-30 characters')
    .matches(/^\+?[0-9\s-]+$/)
    .withMessage('Phone can include digits, spaces, dashes, and leading plus'),
  body('licenseNumber')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 4, max: 80 })
    .withMessage('License number must be 4-80 characters'),
  body('licenseExpiryDate')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('License expiry date must be a valid date')
    .custom((value) => new Date(value).getTime() > Date.now())
    .withMessage('License expiry date must be in the future'),
  body('addressLine1')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 180 })
    .withMessage('Address line 1 must be 180 characters or less'),
  body('address')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 180 })
    .withMessage('Address must be 180 characters or less'),
  body('addressLine2')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 180 })
    .withMessage('Address line 2 must be 180 characters or less'),
  body('city')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('City must be 100 characters or less'),
  body('state')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('State must be 100 characters or less'),
  body('postalCode')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 20 })
    .withMessage('Postal code must be 20 characters or less'),
  body('availabilityStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedAvailabilityStatuses)
    .withMessage(`Availability status must be one of: ${allowedAvailabilityStatuses.join(', ')}`),
  body('driverStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedDriverStatuses)
    .withMessage(`Driver status must be one of: ${allowedDriverStatuses.join(', ')}`),
  body('emergencyContactName')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 120 })
    .withMessage('Emergency contact name must be 120 characters or less'),
  body('emergencyContactPhone')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 7, max: 30 })
    .withMessage('Emergency contact phone must be 7-30 characters')
    .matches(/^\+?[0-9\s-]+$/)
    .withMessage('Emergency contact phone can include digits, spaces, dashes, and leading plus'),
];

const updateDriverValidator = [
  ...driverIdParamValidator,
  ...optionalDriverFields,
  passwordValidator('password'),
];

const driverListValidator = [
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
  query('driverStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedDriverStatuses)
    .withMessage(`Driver status must be one of: ${allowedDriverStatuses.join(', ')}`),
  query('availabilityStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedAvailabilityStatuses)
    .withMessage(`Availability status must be one of: ${allowedAvailabilityStatuses.join(', ')}`),
  query('licenseExpiryFrom')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('License expiry from must be a valid date'),
  query('licenseExpiryTo')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('License expiry to must be a valid date')
    .custom((value, { req }) => {
      if (!req.query.licenseExpiryFrom) {
        return true;
      }

      return new Date(value).getTime()
        >= new Date(req.query.licenseExpiryFrom).getTime();
    })
    .withMessage('License expiry to must be on or after license expiry from'),
  query('city')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('City must be 100 characters or less'),
  query('state')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('State must be 100 characters or less'),
];

module.exports = {
  createDriverValidator,
  driverIdParamValidator,
  driverListValidator,
  updateDriverValidator,
};
