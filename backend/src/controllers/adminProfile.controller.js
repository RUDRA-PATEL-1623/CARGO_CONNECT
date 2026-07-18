const adminProfileService = require('../services/adminProfile.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const getProfile = asyncHandler(async (req, res) => {
  const result = await adminProfileService.getProfile(req.user.id);

  return successResponse({
    res,
    message: 'Admin profile fetched successfully.',
    data: result,
  });
});

const logout = asyncHandler(async (req, res) => {
  const result = await adminProfileService.logout(req.user.id);

  return successResponse({
    res,
    message: 'Admin logout successful.',
    data: result,
  });
});

module.exports = {
  getProfile,
  logout,
};
