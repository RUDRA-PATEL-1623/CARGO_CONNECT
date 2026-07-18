const express = require('express');

const adminSettingsController = require('../controllers/adminSettings.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  settingsQueryValidator,
  updateSettingsValidator,
} = require('../validators/adminSettings.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/settings
 * @description Fetch grouped admin app settings from the database.
 */
router.get(
  '/',
  settingsQueryValidator,
  validateRequest,
  adminSettingsController.getSettings,
);

/**
 * @route PATCH /api/v1/admin/settings
 * @description Update grouped app settings with audit logging.
 */
router.patch(
  '/',
  updateSettingsValidator,
  validateRequest,
  adminSettingsController.updateSettings,
);

module.exports = router;
