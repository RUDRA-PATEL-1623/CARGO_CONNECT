const { body } = require('express-validator');

const allowedDriverAvailabilityStatuses = [
  'available',
  'offline',
  'on_leave',
];

const updateAvailabilityValidator = [
  body('availabilityStatus')
    .trim()
    .notEmpty()
    .withMessage('Availability status is required')
    .isIn(allowedDriverAvailabilityStatuses)
    .withMessage(
      `Availability status must be one of: ${allowedDriverAvailabilityStatuses.join(', ')}`,
    ),
];

module.exports = {
  updateAvailabilityValidator,
};
