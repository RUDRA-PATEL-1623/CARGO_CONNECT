const express = require('express');

const adminReportController = require('../controllers/adminReport.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  driverReportExportValidator,
  driverReportValidator,
  invoiceReportExportValidator,
  invoiceReportValidator,
  paymentReportExportValidator,
  paymentReportValidator,
  shipmentReportExportValidator,
  shipmentReportValidator,
  vehicleReportExportValidator,
  vehicleReportValidator,
} = require('../validators/adminReport.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/reports/shipments
 * @description Fetch shipment operational report with date/status/category filters.
 */
router.get(
  '/reports/shipments',
  shipmentReportValidator,
  validateRequest,
  adminReportController.getShipmentReport,
);

/**
 * @route GET /api/v1/admin/reports/shipments/export
 * @description Export shipment report as CSV or PDF.
 */
router.get(
  '/reports/shipments/export',
  shipmentReportExportValidator,
  validateRequest,
  adminReportController.exportShipmentReport,
);

/**
 * @route GET /api/v1/admin/reports/drivers
 * @description Fetch driver performance report with date/status/category filters.
 */
router.get(
  '/reports/drivers',
  driverReportValidator,
  validateRequest,
  adminReportController.getDriverReport,
);

/**
 * @route GET /api/v1/admin/reports/drivers/export
 * @description Export driver report as CSV or PDF.
 */
router.get(
  '/reports/drivers/export',
  driverReportExportValidator,
  validateRequest,
  adminReportController.exportDriverReport,
);

/**
 * @route GET /api/v1/admin/reports/vehicles
 * @description Fetch vehicle utilization report with date/status/category filters.
 */
router.get(
  '/reports/vehicles',
  vehicleReportValidator,
  validateRequest,
  adminReportController.getVehicleReport,
);

/**
 * @route GET /api/v1/admin/reports/vehicles/export
 * @description Export vehicle report as CSV or PDF.
 */
router.get(
  '/reports/vehicles/export',
  vehicleReportExportValidator,
  validateRequest,
  adminReportController.exportVehicleReport,
);

/**
 * @route GET /api/v1/admin/reports/payments
 * @description Fetch payment report with date/status/category filters.
 */
router.get(
  '/reports/payments',
  paymentReportValidator,
  validateRequest,
  adminReportController.getPaymentReport,
);

/**
 * @route GET /api/v1/admin/reports/payments/export
 * @description Export payment report as CSV or PDF.
 */
router.get(
  '/reports/payments/export',
  paymentReportExportValidator,
  validateRequest,
  adminReportController.exportPaymentReport,
);

/**
 * @route GET /api/v1/admin/reports/invoices
 * @description Fetch invoice report with date/status/category filters.
 */
router.get(
  '/reports/invoices',
  invoiceReportValidator,
  validateRequest,
  adminReportController.getInvoiceReport,
);

/**
 * @route GET /api/v1/admin/reports/invoices/export
 * @description Export invoice report as CSV or PDF.
 */
router.get(
  '/reports/invoices/export',
  invoiceReportExportValidator,
  validateRequest,
  adminReportController.exportInvoiceReport,
);

module.exports = router;
