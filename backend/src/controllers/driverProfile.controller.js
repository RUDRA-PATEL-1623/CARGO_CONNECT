const driverProfileService = require('../services/driverProfile.service');
const asyncHandler = require('../utils/asyncHandler');
const { getRequestMeta } = require('../utils/requestMeta');
const { successResponse } = require('../utils/response');

const getProfile = asyncHandler(async (req, res) => {
  const result = await driverProfileService.getProfile(req.user.id);

  return successResponse({
    res,
    message: 'Driver profile fetched successfully.',
    data: result,
  });
});

const updateAvailability = asyncHandler(async (req, res) => {
  const result = await driverProfileService.updateAvailability({
    userId: req.user.id,
    availabilityStatus: req.body.availabilityStatus,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Driver availability updated successfully.',
    data: result,
  });
});

const logout = asyncHandler(async (req, res) => {
  const result = await driverProfileService.logout({
    userId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Driver logout acknowledged.',
    data: result,
  });
});

module.exports = {
  getProfile,
  logout,
  updateAvailability,
};
