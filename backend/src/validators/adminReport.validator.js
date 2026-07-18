const { query } = require('express-validator');

const shipmentStatuses = [
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
const paymentStatuses = ['unpaid', 'pending', 'paid', 'failed', 'refunded', 'cancelled'];
const invoiceStatuses = ['draft', 'generated', 'void'];
const driverStatuses = ['active', 'inactive', 'suspended'];
const driverAvailabilityStatuses = ['available', 'busy', 'offline', 'on_leave'];
const vehicleAvailabilityStatuses = ['available', 'assigned', 'maintenance', 'inactive'];
const vehicleTypes = ['bike', 'mini_truck', 'truck', 'heavy_truck', 'refrigerated_truck', 'van'];
const paymentMethods = ['upi', 'card', 'cash', 'wallet', 'bank_transfer'];

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

const commonReportFilterValidator = [
  ...paginationValidator,
  ...dateRangeValidator,
  query('search')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 120 })
    .withMessage('Search must be 120 characters or less'),
  query('categoryId')
    .optional({ nullable: true, checkFalsy: true })
    .isInt({ min: 1 })
    .withMessage('Category id must be a positive integer')
    .toInt(),
  query('categoryCode')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 40 })
    .withMessage('Category code must be 40 characters or less'),
];

const enumQuery = (field, values, label = field) => query(field)
  .optional({ nullable: true, checkFalsy: true })
  .isIn(values)
  .withMessage(`${label} must be one of: ${values.join(', ')}`);

const withFormat = (validator) => [
  ...validator,
  query('format')
    .isIn(['csv', 'pdf'])
    .withMessage('Format must be csv or pdf'),
];

const shipmentReportValidator = [
  ...commonReportFilterValidator,
  enumQuery('status', shipmentStatuses, 'Shipment status'),
  enumQuery('paymentStatus', paymentStatuses, 'Payment status'),
];

const driverReportValidator = [
  ...commonReportFilterValidator,
  enumQuery('status', driverStatuses, 'Driver status'),
  enumQuery('driverStatus', driverStatuses, 'Driver status'),
  enumQuery('availabilityStatus', driverAvailabilityStatuses, 'Driver availability status'),
];

const vehicleReportValidator = [
  ...commonReportFilterValidator,
  enumQuery('status', vehicleAvailabilityStatuses, 'Vehicle availability status'),
  enumQuery('availabilityStatus', vehicleAvailabilityStatuses, 'Vehicle availability status'),
  enumQuery('vehicleType', vehicleTypes, 'Vehicle type'),
];

const paymentReportValidator = [
  ...commonReportFilterValidator,
  enumQuery('status', paymentStatuses, 'Payment status'),
  enumQuery('paymentStatus', paymentStatuses, 'Payment status'),
  enumQuery('paymentMethod', paymentMethods, 'Payment method'),
];

const invoiceReportValidator = [
  ...commonReportFilterValidator,
  enumQuery('status', invoiceStatuses, 'Invoice status'),
  enumQuery('invoiceStatus', invoiceStatuses, 'Invoice status'),
  enumQuery('paymentStatus', paymentStatuses, 'Payment status'),
];

module.exports = {
  driverReportExportValidator: withFormat(driverReportValidator),
  driverReportValidator,
  invoiceReportExportValidator: withFormat(invoiceReportValidator),
  invoiceReportValidator,
  paymentReportExportValidator: withFormat(paymentReportValidator),
  paymentReportValidator,
  shipmentReportExportValidator: withFormat(shipmentReportValidator),
  shipmentReportValidator,
  vehicleReportExportValidator: withFormat(vehicleReportValidator),
  vehicleReportValidator,
};
