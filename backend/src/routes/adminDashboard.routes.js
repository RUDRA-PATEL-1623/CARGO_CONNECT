const express = require('express');

const adminDashboardController = require('../controllers/adminDashboard.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  dashboardMetricsValidator,
  recentActivityValidator,
} = require('../validators/adminDashboard.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/dashboard/metrics
 * @description Fetch admin dashboard shipment, driver, vehicle, revenue, and activity metrics.
 */
router.get(
  '/metrics',
  dashboardMetricsValidator,
  validateRequest,
  adminDashboardController.getMetrics,
);

/**
 * @route GET /api/v1/admin/dashboard/recent-activity
 * @description Fetch recent operational activity for the admin dashboard table.
 */
router.get(
  '/recent-activity',
  recentActivityValidator,
  validateRequest,
  adminDashboardController.getRecentActivity,
);

module.exports = router;
