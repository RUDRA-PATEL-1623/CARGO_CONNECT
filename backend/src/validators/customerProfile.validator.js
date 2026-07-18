const { body } = require('express-validator');

const updateProfileValidator = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 120 })
    .withMessage('Name must be 2-120 characters'),
  body('phone')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 7, max: 30 })
    .withMessage('Phone must be 7-30 characters')
    .matches(/^\+?[0-9\s-]+$/)
    .withMessage('Phone can include digits, spaces, dashes, and leading plus'),
  body('avatarUrl')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isURL({ require_protocol: true })
    .withMessage('Avatar URL must be a valid URL')
    .isLength({ max: 500 })
    .withMessage('Avatar URL must be 500 characters or less'),
  body('addressLine1')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 180 })
    .withMessage('Address line 1 must be 180 characters or less'),
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
  body('country')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 80 })
    .withMessage('Country must be 80 characters or less'),
];

module.exports = {
  updateProfileValidator,
};
