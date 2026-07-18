const { body, param, query } = require('express-validator');

const reportTypes = ['accident', 'breakdown', 'route_blocked', 'medical', 'security', 'other'];
const severityLevels = ['low', 'medium', 'high', 'critical'];
const reportStatuses = ['open', 'in_review', 'resolved', 'closed'];
const fuelStatuses = ['pending', 'approved', 'rejected', 'paid'];

const paginationValidator = [
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
];

const reportIdParamValidator = [
  param('reportId')
    .isInt({ min: 1 })
    .withMessage('Report id must be a positive integer')
    .toInt(),
];

const fuelRequestIdParamValidator = [
  param('fuelRequestId')
    .isInt({ min: 1 })
    .withMessage('Fuel request id must be a positive integer')
    .toInt(),
];

const reportListValidator = [
  ...paginationValidator,
  query('search')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 120 })
    .withMessage('Search must be 120 characters or less'),
  query('reportType')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(reportTypes)
    .withMessage(`Report type must be one of: ${reportTypes.join(', ')}`),
  query('severity')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(severityLevels)
    .withMessage(`Severity must be one of: ${severityLevels.join(', ')}`),
  query('status')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(reportStatuses)
    .withMessage(`Status must be one of: ${reportStatuses.join(', ')}`),
  query('driverId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Driver id must be a positive integer')
    .toInt(),
];

const updateReportStatusValidator = [
  ...reportIdParamValidator,
  body('reportStatus')
    .isIn(reportStatuses)
    .withMessage(`Report status must be one of: ${reportStatuses.join(', ')}`),
  body('resolutionNotes')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 2000 })
    .withMessage('Resolution notes must be 2000 characters or less'),
  body('resolutionNotes')
    .if(body('reportStatus').isIn(['resolved', 'closed']))
    .trim()
    .notEmpty()
    .withMessage('Resolution notes are required when resolving or closing a report'),
];

const fuelListValidator = [
  ...paginationValidator,
  query('search')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 120 })
    .withMessage('Search must be 120 characters or less'),
  query('status')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(fuelStatuses)
    .withMessage(`Status must be one of: ${fuelStatuses.join(', ')}`),
  query('driverId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Driver id must be a positive integer')
    .toInt(),
];

const fuelReviewNotesOptional = [
  body('reviewNotes')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 255 })
    .withMessage('Review notes must be 255 characters or less'),
];

const approveFuelRequestValidator = [
  ...fuelRequestIdParamValidator,
  ...fuelReviewNotesOptional,
];

const rejectFuelRequestValidator = [
  ...fuelRequestIdParamValidator,
  body('reviewNotes')
    .trim()
    .notEmpty()
    .withMessage('Review notes are required when rejecting fuel request')
    .isLength({ max: 255 })
    .withMessage('Review notes must be 255 characters or less'),
];

const markFuelPaidValidator = [
  ...fuelRequestIdParamValidator,
  ...fuelReviewNotesOptional,
];

module.exports = {
  approveFuelRequestValidator,
  fuelListValidator,
  fuelRequestIdParamValidator,
  markFuelPaidValidator,
  rejectFuelRequestValidator,
  reportIdParamValidator,
  reportListValidator,
  updateReportStatusValidator,
};
