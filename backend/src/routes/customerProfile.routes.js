const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const customerProfileController = require('../controllers/customerProfile.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const { updateProfileValidator } = require('../validators/customerProfile.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.CUSTOMER));

/**
 * @route GET /api/v1/customer/profile
 * @description Fetch the authenticated customer's profile.
 */
router.get('/profile', customerProfileController.getProfile);

/**
 * @route PATCH /api/v1/customer/profile
 * @description Update the authenticated customer's editable profile fields.
 */
router.patch(
  '/profile',
  updateProfileValidator,
  validateRequest,
  customerProfileController.updateProfile,
);

module.exports = router;
