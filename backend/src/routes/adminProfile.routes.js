const express = require('express');

const adminProfileController = require('../controllers/adminProfile.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/profile
 * @description Fetch authenticated admin or dispatcher profile.
 */
router.get('/profile', adminProfileController.getProfile);

/**
 * @route POST /api/v1/admin/logout
 * @description Stateless logout acknowledgement. Clients must discard JWT.
 */
router.post('/logout', adminProfileController.logout);

module.exports = router;
