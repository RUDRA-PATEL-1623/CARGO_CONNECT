const { body, param } = require('express-validator');

const assignmentIdParamValidator = [
  param('assignmentId')
    .isInt({ min: 1 })
    .withMessage('Assignment id must be a positive integer')
    .toInt(),
];

const assignmentResourceFields = [
  body('driverId')
    .isInt({ min: 1 })
    .withMessage('Driver id must be a positive integer')
    .toInt(),
  body('vehicleId')
    .isInt({ min: 1 })
    .withMessage('Vehicle id must be a positive integer')
    .toInt(),
  body('notes')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be 500 characters or less'),
];

const createAssignmentValidator = [
  body('shipmentId')
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
  ...assignmentResourceFields,
];

const replaceAssignmentValidator = [
  ...assignmentIdParamValidator,
  ...assignmentResourceFields,
];

const validateAssignmentConflictsValidator = [
  body('shipmentId')
    .isInt({ min: 1 })
    .withMessage('Shipment id must be a positive integer')
    .toInt(),
  ...assignmentResourceFields,
  body('replaceAssignmentId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Replace assignment id must be a positive integer')
    .toInt(),
];

module.exports = {
  createAssignmentValidator,
  replaceAssignmentValidator,
  validateAssignmentConflictsValidator,
};
