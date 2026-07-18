const { body, param, query } = require('express-validator');

const allowedAssignmentStatuses = [
  'assigned',
  'accepted',
  'rejected',
  'started',
  'pickup_completed',
  'in_transit',
  'delivered',
  'completed',
  'cancelled',
];

const allowedShipmentStatuses = [
  'pending',
  'approved',
  'assigned',
  'accepted',
  'pickup_completed',
  'in_transit',
  'delivered',
  'completed',
  'cancelled',
  'rejected',
];

const allowedTripGroups = [
  'new',
  'accepted',
  'in_progress',
  'completed',
  'rejected',
  'history',
];

const allowedTripUpdateStatuses = [
  'in_transit',
  'delayed',
  'issue_reported',
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

const assignmentIdParamValidator = [
  param('assignmentId')
    .isInt({ min: 1 })
    .withMessage('Assignment id must be a positive integer')
    .toInt(),
];

const assignedTripListValidator = [
  ...paginationValidator,
  query('search')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 120 })
    .withMessage('Search must be 120 characters or less'),
  query('group')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedTripGroups)
    .withMessage(`Group must be one of: ${allowedTripGroups.join(', ')}`),
  query('status')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedAssignmentStatuses)
    .withMessage(`Status must be one of: ${allowedAssignmentStatuses.join(', ')}`),
  query('shipmentStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedShipmentStatuses)
    .withMessage(`Shipment status must be one of: ${allowedShipmentStatuses.join(', ')}`),
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

const acceptTripValidator = [
  ...assignmentIdParamValidator,
];

const rejectTripValidator = [
  ...assignmentIdParamValidator,
  body('reason')
    .trim()
    .notEmpty()
    .withMessage('Reject reason is required')
    .isLength({ min: 5, max: 255 })
    .withMessage('Reject reason must be 5-255 characters'),
];

const progressBodyValidator = [
  body('notes')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be 500 characters or less'),
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
  body('etaMinutes')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1, max: 1440 })
    .withMessage('ETA minutes must be between 1 and 1440')
    .toInt(),
];

const tripProgressValidator = [
  ...assignmentIdParamValidator,
  ...progressBodyValidator,
];

const tripStatusUpdateValidator = [
  ...assignmentIdParamValidator,
  ...progressBodyValidator,
  body('status')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedTripUpdateStatuses)
    .withMessage(`Status must be one of: ${allowedTripUpdateStatuses.join(', ')}`),
  body('delayReason')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Delay reason must be 500 characters or less'),
  body()
    .custom((value) => {
      if (value.status === 'delayed' && !value.delayReason && !value.notes) {
        throw new Error('Delay reason or notes are required when reporting a delay');
      }

      if (value.status === 'issue_reported' && !value.notes) {
        throw new Error('Notes are required when reporting an in-transit issue');
      }

      return true;
    }),
];

const proofUploadValidator = [
  ...assignmentIdParamValidator,
  ...progressBodyValidator,
  body('capturedAt')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Captured at must be a valid ISO date'),
];

module.exports = {
  acceptTripValidator,
  assignedTripListValidator,
  assignmentIdParamValidator,
  proofUploadValidator,
  rejectTripValidator,
  tripStatusUpdateValidator,
  tripProgressValidator,
};
