const { body, param, query } = require('express-validator');

const allowedAccountStatuses = ['active', 'inactive', 'blocked'];
const allowedUserStatuses = ['active', 'inactive', 'suspended'];

const customerIdParamValidator = [
  param('customerId')
    .isInt({ min: 1 })
    .withMessage('Customer id must be a positive integer')
    .toInt(),
];

const customerListValidator = [
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
  query('accountStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedAccountStatuses)
    .withMessage(`Account status must be one of: ${allowedAccountStatuses.join(', ')}`),
  query('userStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedUserStatuses)
    .withMessage(`User status must be one of: ${allowedUserStatuses.join(', ')}`),
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

const deactivateCustomerValidator = [
  ...customerIdParamValidator,
  body('reason')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 255 })
    .withMessage('Reason must be 255 characters or less'),
];

module.exports = {
  customerIdParamValidator,
  customerListValidator,
  deactivateCustomerValidator,
};
