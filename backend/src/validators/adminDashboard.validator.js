const { query } = require('express-validator');

const dateRangeValidator = [
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

const dashboardMetricsValidator = [
  ...dateRangeValidator,
  query('activityLimit')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1, max: 20 })
    .withMessage('Activity limit must be between 1 and 20')
    .toInt(),
];

const recentActivityValidator = [
  query('limit')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1, max: 20 })
    .withMessage('Limit must be between 1 and 20')
    .toInt(),
];

module.exports = {
  dashboardMetricsValidator,
  recentActivityValidator,
};
