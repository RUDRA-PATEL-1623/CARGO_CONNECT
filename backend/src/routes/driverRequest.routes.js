const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const driverRequestController = require('../controllers/driverRequest.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const {
  uploadFuelBill,
  uploadReportAttachment,
} = require('../middleware/requestUpload.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  createBreakdownReportValidator,
  createEmergencyReportValidator,
  createFuelRequestValidator,
  fuelBillUploadValidator,
  fuelRequestListValidator,
  reportListValidator,
} = require('../validators/driverRequest.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.DRIVER));

/**
 * @route GET /api/v1/driver/reports
 * @description List reports submitted by the authenticated driver.
 */
router.get(
  '/reports',
  reportListValidator,
  validateRequest,
  driverRequestController.listReports,
);

/**
 * @route POST /api/v1/driver/reports/emergency
 * @description Submit an emergency report with optional attachment.
 */
router.post(
  '/reports/emergency',
  uploadReportAttachment,
  createEmergencyReportValidator,
  validateRequest,
  driverRequestController.createEmergencyReport,
);

/**
 * @route POST /api/v1/driver/reports/breakdown
 * @description Submit a vehicle breakdown report with optional attachment.
 */
router.post(
  '/reports/breakdown',
  uploadReportAttachment,
  createBreakdownReportValidator,
  validateRequest,
  driverRequestController.createBreakdownReport,
);

/**
 * @route GET /api/v1/driver/fuel-requests
 * @description List fuel requests submitted by the authenticated driver.
 */
router.get(
  '/fuel-requests',
  fuelRequestListValidator,
  validateRequest,
  driverRequestController.listFuelRequests,
);

/**
 * @route POST /api/v1/driver/fuel-requests
 * @description Submit a fuel request.
 */
router.post(
  '/fuel-requests',
  createFuelRequestValidator,
  validateRequest,
  driverRequestController.createFuelRequest,
);

/**
 * @route POST /api/v1/driver/fuel-requests/:fuelRequestId/bill
 * @description Upload bill file for a pending driver-owned fuel request.
 */
router.post(
  '/fuel-requests/:fuelRequestId/bill',
  uploadFuelBill,
  fuelBillUploadValidator,
  validateRequest,
  driverRequestController.uploadFuelBill,
);

module.exports = router;
