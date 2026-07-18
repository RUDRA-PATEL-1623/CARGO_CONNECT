const express = require('express');

const adminRequestController = require('../controllers/adminRequest.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  approveFuelRequestValidator,
  fuelListValidator,
  fuelRequestIdParamValidator,
  markFuelPaidValidator,
  rejectFuelRequestValidator,
  reportIdParamValidator,
  reportListValidator,
  updateReportStatusValidator,
} = require('../validators/adminRequest.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/reports
 * @description List emergency and breakdown reports with filters.
 */
router.get(
  '/reports',
  reportListValidator,
  validateRequest,
  adminRequestController.listReports,
);

/**
 * @route GET /api/v1/admin/reports/:reportId
 * @description Fetch one emergency or breakdown report.
 */
router.get(
  '/reports/:reportId',
  reportIdParamValidator,
  validateRequest,
  adminRequestController.getReportDetails,
);

/**
 * @route PATCH /api/v1/admin/reports/:reportId/status
 * @description Update report review/resolution status.
 */
router.patch(
  '/reports/:reportId/status',
  updateReportStatusValidator,
  validateRequest,
  adminRequestController.updateReportStatus,
);

/**
 * @route GET /api/v1/admin/fuel-requests
 * @description List fuel requests with filters.
 */
router.get(
  '/fuel-requests',
  fuelListValidator,
  validateRequest,
  adminRequestController.listFuelRequests,
);

/**
 * @route GET /api/v1/admin/fuel-requests/:fuelRequestId
 * @description Fetch one fuel request.
 */
router.get(
  '/fuel-requests/:fuelRequestId',
  fuelRequestIdParamValidator,
  validateRequest,
  adminRequestController.getFuelRequestDetails,
);

/**
 * @route PATCH /api/v1/admin/fuel-requests/:fuelRequestId/approve
 * @description Approve a pending fuel request after bill upload.
 */
router.patch(
  '/fuel-requests/:fuelRequestId/approve',
  approveFuelRequestValidator,
  validateRequest,
  adminRequestController.approveFuelRequest,
);

/**
 * @route PATCH /api/v1/admin/fuel-requests/:fuelRequestId/reject
 * @description Reject a pending fuel request with review notes.
 */
router.patch(
  '/fuel-requests/:fuelRequestId/reject',
  rejectFuelRequestValidator,
  validateRequest,
  adminRequestController.rejectFuelRequest,
);

/**
 * @route PATCH /api/v1/admin/fuel-requests/:fuelRequestId/mark-paid
 * @description Mark an approved fuel request as paid.
 */
router.patch(
  '/fuel-requests/:fuelRequestId/mark-paid',
  markFuelPaidValidator,
  validateRequest,
  adminRequestController.markFuelRequestPaid,
);

module.exports = router;
