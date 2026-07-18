const { body, param, query } = require('express-validator');

const reportTypes = ['accident', 'route_blocked', 'medical', 'security', 'other'];
const severityLevels = ['low', 'medium', 'high', 'critical'];
const reportStatuses = ['open', 'in_review', 'resolved', 'closed'];
const fuelStatuses = ['pending', 'approved', 'rejected', 'paid'];
const breakdownIssueTypes = [
  'engine',
  'tyre',
  'battery',
  'fuel',
  'electrical',
  'cooling',
  'accident_damage',
  'other',
];

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

const contextFields = [
  body('assignmentId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Assignment id must be a positive integer')
    .toInt(),
  body('vehicleId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Vehicle id must be a positive integer')
    .toInt(),
];

const locationFields = [
  body('locationText')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 255 })
    .withMessage('Location text must be 255 characters or less'),
  body('latitude')
    .optional({ nullable: true })
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90')
    .toFloat()
    .custom((value, { req }) => {
      if (value !== undefined && value !== null && req.body.longitude === undefined) {
        throw new Error('Longitude is required when latitude is provided');
      }

      return true;
    }),
  body('longitude')
    .optional({ nullable: true })
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180')
    .toFloat()
    .custom((value, { req }) => {
      if (value !== undefined && value !== null && req.body.latitude === undefined) {
        throw new Error('Latitude is required when longitude is provided');
      }

      return true;
    }),
];

const createEmergencyReportValidator = [
  body('reportType')
    .isIn(reportTypes)
    .withMessage(`Report type must be one of: ${reportTypes.join(', ')}`),
  body('severity')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(severityLevels)
    .withMessage(`Severity must be one of: ${severityLevels.join(', ')}`),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ max: 2000 })
    .withMessage('Description must be 2000 characters or less'),
  ...contextFields,
  ...locationFields,
];

const createBreakdownReportValidator = [
  body('issueType')
    .isIn(breakdownIssueTypes)
    .withMessage(`Issue type must be one of: ${breakdownIssueTypes.join(', ')}`),
  body('severity')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(severityLevels)
    .withMessage(`Severity must be one of: ${severityLevels.join(', ')}`),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ max: 2000 })
    .withMessage('Description must be 2000 characters or less'),
  body('vehicleId')
    .isInt({ min: 1 })
    .withMessage('Vehicle id is required for breakdown reports')
    .toInt(),
  body('assignmentId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Assignment id must be a positive integer')
    .toInt(),
  ...locationFields,
];

const reportListValidator = [
  ...paginationValidator,
  query('reportType')
    .optional({ nullable: true, checkFalsy: true })
    .isIn([...reportTypes, 'breakdown'])
    .withMessage(`Report type must be one of: ${[...reportTypes, 'breakdown'].join(', ')}`),
  query('status')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(reportStatuses)
    .withMessage(`Status must be one of: ${reportStatuses.join(', ')}`),
];

const createFuelRequestValidator = [
  body('fuelAmountLiters')
    .isFloat({ min: 0.01 })
    .withMessage('Fuel amount must be greater than 0')
    .toFloat(),
  body('billAmount')
    .isFloat({ min: 0 })
    .withMessage('Bill amount must be 0 or greater')
    .toFloat(),
  body('fuelStation')
    .trim()
    .notEmpty()
    .withMessage('Fuel station is required')
    .isLength({ max: 160 })
    .withMessage('Fuel station must be 160 characters or less'),
  body('notes')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Notes must be 1000 characters or less'),
  ...contextFields,
  body()
    .custom((value) => Boolean(value.assignmentId || value.vehicleId))
    .withMessage('Either assignmentId or vehicleId is required'),
];

const fuelRequestListValidator = [
  ...paginationValidator,
  query('status')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(fuelStatuses)
    .withMessage(`Status must be one of: ${fuelStatuses.join(', ')}`),
];

const fuelRequestIdParamValidator = [
  param('fuelRequestId')
    .isInt({ min: 1 })
    .withMessage('Fuel request id must be a positive integer')
    .toInt(),
];

const fuelBillUploadValidator = [
  ...fuelRequestIdParamValidator,
  body('notes')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Notes must be 1000 characters or less'),
];

module.exports = {
  createBreakdownReportValidator,
  createEmergencyReportValidator,
  createFuelRequestValidator,
  fuelBillUploadValidator,
  fuelRequestListValidator,
  reportListValidator,
};
