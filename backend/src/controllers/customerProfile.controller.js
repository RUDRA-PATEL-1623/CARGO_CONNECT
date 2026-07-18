const customerProfileService = require('../services/customerProfile.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const getProfile = asyncHandler(async (req, res) => {
  const result = await customerProfileService.getProfile(req.user.id);

  return successResponse({
    res,
    message: 'Customer profile fetched successfully.',
    data: result,
  });
});

const updateProfile = asyncHandler(async (req, res) => {
  const result = await customerProfileService.updateProfile(req.user.id, req.body);

  return successResponse({
    res,
    message: 'Customer profile updated successfully.',
    data: result,
  });
});

module.exports = {
  getProfile,
  updateProfile,
};
