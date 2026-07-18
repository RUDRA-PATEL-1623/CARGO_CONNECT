const express = require('express');

const adminVehicleController = require('../controllers/adminVehicle.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  createVehicleValidator,
  updateVehicleValidator,
  vehicleIdParamValidator,
  vehicleListValidator,
} = require('../validators/adminVehicle.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/vehicles
 * @description List vehicles with search, type, fuel, service, insurance, availability filters, and pagination.
 */
router.get(
  '/',
  vehicleListValidator,
  validateRequest,
  adminVehicleController.listVehicles,
);

/**
 * @route POST /api/v1/admin/vehicles
 * @description Create a vehicle record.
 */
router.post(
  '/',
  createVehicleValidator,
  validateRequest,
  adminVehicleController.createVehicle,
);

/**
 * @route GET /api/v1/admin/vehicles/:vehicleId
 * @description Fetch vehicle details, assigned driver, and recent assignments.
 */
router.get(
  '/:vehicleId',
  vehicleIdParamValidator,
  validateRequest,
  adminVehicleController.getVehicleDetails,
);

/**
 * @route PATCH /api/v1/admin/vehicles/:vehicleId
 * @description Update vehicle registration, capacity, type, expiry, service, and availability fields.
 */
router.patch(
  '/:vehicleId',
  updateVehicleValidator,
  validateRequest,
  adminVehicleController.updateVehicle,
);

/**
 * @route PATCH /api/v1/admin/vehicles/:vehicleId/activate
 * @description Activate a vehicle for dispatch.
 */
router.patch(
  '/:vehicleId/activate',
  vehicleIdParamValidator,
  validateRequest,
  adminVehicleController.activateVehicle,
);

/**
 * @route PATCH /api/v1/admin/vehicles/:vehicleId/deactivate
 * @description Deactivate a vehicle and clear driver assignment.
 */
router.patch(
  '/:vehicleId/deactivate',
  vehicleIdParamValidator,
  validateRequest,
  adminVehicleController.deactivateVehicle,
);

module.exports = router;
