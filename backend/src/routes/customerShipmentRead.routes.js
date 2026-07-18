const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const customerShipmentReadController = require('../controllers/customerShipmentRead.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  proofDetailValidator,
  proofListValidator,
  shipmentHistoryValidator,
  shipmentIdParamValidator,
} = require('../validators/customerShipmentRead.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.CUSTOMER));

/**
 * @route GET /api/v1/customer/shipments
 * @description List customer-owned shipments with search, status, date, and category filters.
 */
router.get(
  '/shipments',
  shipmentHistoryValidator,
  validateRequest,
  customerShipmentReadController.listHistory,
);

/**
 * @route GET /api/v1/customer/shipments/:shipmentId/timeline
 * @description Fetch customer-owned shipment status timeline.
 */
router.get(
  '/shipments/:shipmentId/timeline',
  shipmentIdParamValidator,
  validateRequest,
  customerShipmentReadController.getTimeline,
);

/**
 * @route GET /api/v1/customer/shipments/:shipmentId/tracking
 * @description Fetch customer-owned shipment tracking summary.
 */
router.get(
  '/shipments/:shipmentId/tracking',
  shipmentIdParamValidator,
  validateRequest,
  customerShipmentReadController.getTracking,
);

/**
 * @route GET /api/v1/customer/shipments/:shipmentId/proofs
 * @description List pickup/delivery proof uploads for a customer-owned shipment.
 */
router.get(
  '/shipments/:shipmentId/proofs',
  proofListValidator,
  validateRequest,
  customerShipmentReadController.listProofs,
);

/**
 * @route GET /api/v1/customer/shipments/:shipmentId/proofs/:proofId
 * @description Fetch one proof upload for a customer-owned shipment.
 */
router.get(
  '/shipments/:shipmentId/proofs/:proofId',
  proofDetailValidator,
  validateRequest,
  customerShipmentReadController.getProof,
);

/**
 * @route GET /api/v1/customer/shipments/:shipmentId
 * @description Fetch customer-owned shipment details.
 */
router.get(
  '/shipments/:shipmentId',
  shipmentIdParamValidator,
  validateRequest,
  customerShipmentReadController.getDetails,
);

module.exports = router;
