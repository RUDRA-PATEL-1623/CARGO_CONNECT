const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const driverProfileController = require('../controllers/driverProfile.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const { updateAvailabilityValidator } = require('../validators/driverProfile.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.DRIVER));

/**
 * @route GET /api/v1/driver/profile
 * @description Fetch authenticated driver profile and active assignment count.
 */
router.get('/profile', driverProfileController.getProfile);

/**
 * @route PATCH /api/v1/driver/availability
 * @description Update driver availability when no active assignment is in progress.
 */
router.patch(
  '/availability',
  updateAvailabilityValidator,
  validateRequest,
  driverProfileController.updateAvailability,
);

/**
 * @route POST /api/v1/driver/logout
 * @description Stateless driver logout acknowledgement; clients should discard JWTs.
 */
router.post('/logout', driverProfileController.logout);

module.exports = router;
