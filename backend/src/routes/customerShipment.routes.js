const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const customerShipmentController = require('../controllers/customerShipment.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  createShipmentValidator,
  estimateValidator,
  placeOrderValidator,
  shipmentIdParamValidator,
} = require('../validators/customerShipment.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.CUSTOMER));

/**
 * @route POST /api/v1/customer/shipments/estimate
 * @description Calculate a basic customer shipment price estimate.
 */
router.post(
  '/shipments/estimate',
  estimateValidator,
  validateRequest,
  customerShipmentController.calculateEstimate,
);

/**
 * @route POST /api/v1/customer/shipments
 * @description Create a pending customer shipment request with UI form fields.
 */
router.post(
  '/shipments',
  createShipmentValidator,
  validateRequest,
  customerShipmentController.createShipmentRequest,
);

/**
 * @route GET /api/v1/customer/shipments/:shipmentId/summary
 * @description Fetch customer-owned shipment summary.
 */
router.get(
  '/shipments/:shipmentId/summary',
  shipmentIdParamValidator,
  validateRequest,
  customerShipmentController.getShipmentSummary,
);

/**
 * @route POST /api/v1/customer/shipments/:shipmentId/place-order
 * @description Place a customer shipment order after mock payment.
 */
router.post(
  '/shipments/:shipmentId/place-order',
  placeOrderValidator,
  validateRequest,
  customerShipmentController.placeOrder,
);

module.exports = router;
