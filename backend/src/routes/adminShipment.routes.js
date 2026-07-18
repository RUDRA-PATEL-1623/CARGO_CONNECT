const express = require('express');

const adminShipmentController = require('../controllers/adminShipment.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  approveShipmentValidator,
  reasonActionValidator,
  reassignShipmentValidator,
  shipmentIdParamValidator,
  shipmentListValidator,
} = require('../validators/adminShipment.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/shipments
 * @description List shipments with search, status, payment, category, date, and assignment filters.
 */
router.get(
  '/',
  shipmentListValidator,
  validateRequest,
  adminShipmentController.listShipments,
);

/**
 * @route GET /api/v1/admin/shipments/:shipmentId
 * @description Fetch shipment details, payment, invoice, assignments, proofs, and trip logs.
 */
router.get(
  '/:shipmentId',
  shipmentIdParamValidator,
  validateRequest,
  adminShipmentController.getShipmentDetails,
);

/**
 * @route PATCH /api/v1/admin/shipments/:shipmentId/approve
 * @description Approve a paid pending shipment.
 */
router.patch(
  '/:shipmentId/approve',
  approveShipmentValidator,
  validateRequest,
  adminShipmentController.approveShipment,
);

/**
 * @route PATCH /api/v1/admin/shipments/:shipmentId/reject
 * @description Reject a pending shipment with a required reason.
 */
router.patch(
  '/:shipmentId/reject',
  reasonActionValidator,
  validateRequest,
  adminShipmentController.rejectShipment,
);

/**
 * @route PATCH /api/v1/admin/shipments/:shipmentId/cancel
 * @description Cancel a non-terminal shipment with a required reason.
 */
router.patch(
  '/:shipmentId/cancel',
  reasonActionValidator,
  validateRequest,
  adminShipmentController.cancelShipment,
);

/**
 * @route PATCH /api/v1/admin/shipments/:shipmentId/reassign
 * @description Assign or reassign an approved/assigned/accepted shipment to a driver and vehicle.
 */
router.patch(
  '/:shipmentId/reassign',
  reassignShipmentValidator,
  validateRequest,
  adminShipmentController.reassignShipment,
);

module.exports = router;
