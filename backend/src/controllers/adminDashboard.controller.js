const adminDashboardService = require('../services/adminDashboard.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const getMetrics = asyncHandler(async (req, res) => {
  const result = await adminDashboardService.getDashboardMetrics(req.query);

  return successResponse({
    res,
    message: 'Admin dashboard metrics fetched successfully.',
    data: result,
  });
});

const getRecentActivity = asyncHandler(async (req, res) => {
  const result = await adminDashboardService.getRecentActivity(req.query);

  return successResponse({
    res,
    message: 'Admin recent activity fetched successfully.',
    data: result,
  });
});

module.exports = {
  getMetrics,
  getRecentActivity,
};
