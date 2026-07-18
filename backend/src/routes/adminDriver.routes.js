const express = require('express');

const adminDriverController = require('../controllers/adminDriver.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  createDriverValidator,
  driverIdParamValidator,
  driverListValidator,
  updateDriverValidator,
} = require('../validators/adminDriver.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/drivers
 * @description List drivers with search, status, availability, license filters, and pagination.
 */
router.get(
  '/',
  driverListValidator,
  validateRequest,
  adminDriverController.listDrivers,
);

/**
 * @route POST /api/v1/admin/drivers
 * @description Create a driver profile and linked driver login credentials.
 */
router.post(
  '/',
  createDriverValidator,
  validateRequest,
  adminDriverController.createDriver,
);

/**
 * @route GET /api/v1/admin/drivers/:driverId
 * @description Fetch driver details, performance summary, vehicle, and recent assignments.
 */
router.get(
  '/:driverId',
  driverIdParamValidator,
  validateRequest,
  adminDriverController.getDriverDetails,
);

/**
 * @route PATCH /api/v1/admin/drivers/:driverId
 * @description Update driver profile and login fields.
 */
router.patch(
  '/:driverId',
  updateDriverValidator,
  validateRequest,
  adminDriverController.updateDriver,
);

/**
 * @route PATCH /api/v1/admin/drivers/:driverId/activate
 * @description Activate driver login and profile.
 */
router.patch(
  '/:driverId/activate',
  driverIdParamValidator,
  validateRequest,
  adminDriverController.activateDriver,
);

/**
 * @route PATCH /api/v1/admin/drivers/:driverId/deactivate
 * @description Deactivate driver login and profile.
 */
router.patch(
  '/:driverId/deactivate',
  driverIdParamValidator,
  validateRequest,
  adminDriverController.deactivateDriver,
);

module.exports = router;
