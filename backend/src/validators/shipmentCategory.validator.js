const { body, param, query } = require('express-validator');

const allowedVehicleSuggestions = [
  'bike',
  'mini_truck',
  'truck',
  'heavy_truck',
  'refrigerated_truck',
  'van',
];

const categoryIdParamValidator = [
  param('categoryId')
    .isInt({ min: 1 })
    .withMessage('Category id must be a positive integer'),
];

const adminCategoryListValidator = [
  query('includeInactive')
    .optional()
    .isBoolean()
    .withMessage('includeInactive must be true or false'),
  query('search')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('Search must be 100 characters or less'),
];

const baseCategoryFields = [
  body('description')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 255 })
    .withMessage('Description must be 255 characters or less'),
  body('vehicleSuggestion')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedVehicleSuggestions)
    .withMessage(`Vehicle suggestion must be one of: ${allowedVehicleSuggestions.join(', ')}`),
  body('iconKey')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 80 })
    .withMessage('Icon key must be 80 characters or less')
    .matches(/^[a-z0-9._-]+$/)
    .withMessage('Icon key can only contain lowercase letters, numbers, dots, dashes, and underscores'),
  body('basePrice')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Base price must be 0 or greater'),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('Active status must be true or false'),
  body('sortOrder')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Sort order must be 0 or greater'),
];

const createCategoryValidator = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be 2-100 characters'),
  body('code')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 2, max: 40 })
    .withMessage('Code must be 2-40 characters')
    .matches(/^[A-Za-z0-9_-]+$/)
    .withMessage('Code can only contain letters, numbers, dashes, and underscores'),
  body('basePrice')
    .isFloat({ min: 0 })
    .withMessage('Base price is required and must be 0 or greater'),
  body('vehicleSuggestion')
    .notEmpty()
    .withMessage('Vehicle suggestion is required')
    .isIn(allowedVehicleSuggestions)
    .withMessage(`Vehicle suggestion must be one of: ${allowedVehicleSuggestions.join(', ')}`),
  body('iconKey')
    .trim()
    .notEmpty()
    .withMessage('Icon key is required')
    .isLength({ max: 80 })
    .withMessage('Icon key must be 80 characters or less')
    .matches(/^[a-z0-9._-]+$/)
    .withMessage('Icon key can only contain lowercase letters, numbers, dots, dashes, and underscores'),
  ...baseCategoryFields,
];

const updateCategoryValidator = [
  ...categoryIdParamValidator,
  body()
    .custom((value) => {
      const allowed = [
        'name',
        'description',
        'basePrice',
        'vehicleSuggestion',
        'iconKey',
        'isActive',
        'sortOrder',
      ];

      return allowed.some((field) => Object.prototype.hasOwnProperty.call(value, field));
    })
    .withMessage('At least one category field is required'),
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be 2-100 characters'),
  ...baseCategoryFields,
];

module.exports = {
  adminCategoryListValidator,
  categoryIdParamValidator,
  createCategoryValidator,
  updateCategoryValidator,
};
