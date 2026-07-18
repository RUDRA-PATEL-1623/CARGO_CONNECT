const { body, param, query } = require('express-validator');

const allowedVehicleTypes = [
  'bike',
  'mini_truck',
  'truck',
  'heavy_truck',
  'refrigerated_truck',
  'van',
];
const allowedFuelTypes = ['petrol', 'diesel', 'cng', 'electric', 'hybrid'];
const allowedAvailabilityStatuses = [
  'available',
  'assigned',
  'maintenance',
  'inactive',
];

const vehicleIdParamValidator = [
  param('vehicleId')
    .isInt({ min: 1 })
    .withMessage('Vehicle id must be a positive integer')
    .toInt(),
];

const vehicleNumberValidator = (source = body) => [
  source('vehicleNumber')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 3, max: 40 })
    .withMessage('Vehicle number must be 3-40 characters')
    .matches(/^[A-Za-z0-9-]+$/)
    .withMessage('Vehicle number can include letters, numbers, and dashes'),
];

const registrationValidator = (required = true) => {
  const chain = body('registrationNumber');

  return required
    ? chain
        .trim()
        .notEmpty()
        .withMessage('Registration number is required')
        .isLength({ min: 4, max: 80 })
        .withMessage('Registration number must be 4-80 characters')
    : chain
        .optional({ nullable: true, checkFalsy: true })
        .trim()
        .isLength({ min: 4, max: 80 })
        .withMessage('Registration number must be 4-80 characters');
};

const typeValidators = (required = true) => [
  body('vehicleType')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedVehicleTypes)
    .withMessage(`Vehicle type must be one of: ${allowedVehicleTypes.join(', ')}`),
  body('type')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedVehicleTypes)
    .withMessage(`Type must be one of: ${allowedVehicleTypes.join(', ')}`),
  body()
    .custom((value) => {
      if (!required) {
        return true;
      }

      return Boolean(value.vehicleType || value.type);
    })
    .withMessage('Vehicle type is required'),
];

const capacityValidators = (required = true) => [
  body('capacityKg')
    .optional({ nullable: true, checkFalsy: true })
    .isFloat({ gt: 0 })
    .withMessage('Capacity must be greater than 0')
    .toFloat(),
  body('capacity')
    .optional({ nullable: true, checkFalsy: true })
    .isFloat({ gt: 0 })
    .withMessage('Capacity must be greater than 0')
    .toFloat(),
  body()
    .custom((value) => {
      if (!required) {
        return true;
      }

      return value.capacityKg !== undefined || value.capacity !== undefined;
    })
    .withMessage('Capacity is required'),
];

const commonVehicleFields = [
  ...vehicleNumberValidator(),
  body('model')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 120 })
    .withMessage('Model must be 120 characters or less'),
  body('fuelType')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedFuelTypes)
    .withMessage(`Fuel type must be one of: ${allowedFuelTypes.join(', ')}`),
  body('insuranceExpiryDate')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Insurance expiry date must be a valid date'),
  body('insuranceExpiry')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Insurance expiry must be a valid date'),
  body('serviceDueDate')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Service due date must be a valid date'),
  body('serviceDue')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Service due must be a valid date'),
  body('availabilityStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedAvailabilityStatuses)
    .withMessage(`Availability status must be one of: ${allowedAvailabilityStatuses.join(', ')}`),
  body('availability')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedAvailabilityStatuses)
    .withMessage(`Availability must be one of: ${allowedAvailabilityStatuses.join(', ')}`),
  body('assignedDriverId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Assigned driver id must be a positive integer')
    .toInt(),
  body('notes')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 2000 })
    .withMessage('Notes must be 2000 characters or less'),
];

const createVehicleValidator = [
  registrationValidator(true),
  ...typeValidators(true),
  ...capacityValidators(true),
  body('fuelType')
    .notEmpty()
    .withMessage('Fuel type is required')
    .isIn(allowedFuelTypes)
    .withMessage(`Fuel type must be one of: ${allowedFuelTypes.join(', ')}`),
  ...commonVehicleFields,
];

const updateVehicleValidator = [
  ...vehicleIdParamValidator,
  registrationValidator(false),
  ...typeValidators(false),
  ...capacityValidators(false),
  ...commonVehicleFields,
];

const vehicleListValidator = [
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
  query('vehicleType')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedVehicleTypes)
    .withMessage(`Vehicle type must be one of: ${allowedVehicleTypes.join(', ')}`),
  query('fuelType')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedFuelTypes)
    .withMessage(`Fuel type must be one of: ${allowedFuelTypes.join(', ')}`),
  query('availabilityStatus')
    .optional({ nullable: true, checkFalsy: true })
    .isIn(allowedAvailabilityStatuses)
    .withMessage(`Availability status must be one of: ${allowedAvailabilityStatuses.join(', ')}`),
  query('assignedDriverId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Assigned driver id must be a positive integer')
    .toInt(),
  query('insuranceExpiryFrom')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Insurance expiry from must be a valid date'),
  query('insuranceExpiryTo')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Insurance expiry to must be a valid date')
    .custom((value, { req }) => {
      if (!req.query.insuranceExpiryFrom) {
        return true;
      }

      return new Date(value).getTime()
        >= new Date(req.query.insuranceExpiryFrom).getTime();
    })
    .withMessage('Insurance expiry to must be on or after insurance expiry from'),
  query('serviceDueFrom')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Service due from must be a valid date'),
  query('serviceDueTo')
    .optional({ nullable: true, checkFalsy: true })
    .isISO8601()
    .withMessage('Service due to must be a valid date')
    .custom((value, { req }) => {
      if (!req.query.serviceDueFrom) {
        return true;
      }

      return new Date(value).getTime()
        >= new Date(req.query.serviceDueFrom).getTime();
    })
    .withMessage('Service due to must be on or after service due from'),
];

module.exports = {
  createVehicleValidator,
  updateVehicleValidator,
  vehicleIdParamValidator,
  vehicleListValidator,
};
