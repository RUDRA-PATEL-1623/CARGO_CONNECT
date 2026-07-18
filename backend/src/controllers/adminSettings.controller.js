const adminSettingsService = require('../services/adminSettings.service');
const asyncHandler = require('../utils/asyncHandler');
const { getRequestMeta } = require('../utils/requestMeta');
const { successResponse } = require('../utils/response');

const getSettings = asyncHandler(async (req, res) => {
  const result = await adminSettingsService.getSettings(req.query);

  return successResponse({
    res,
    message: 'Admin settings fetched successfully.',
    data: result,
  });
});

const updateSettings = asyncHandler(async (req, res) => {
  const result = await adminSettingsService.updateSettings({
    payload: req.body,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Admin settings saved successfully.',
    data: result,
  });
});

module.exports = {
  getSettings,
  updateSettings,
};
