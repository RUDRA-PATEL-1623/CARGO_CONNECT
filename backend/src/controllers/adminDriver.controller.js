const adminDriverService = require('../services/adminDriver.service');
const asyncHandler = require('../utils/asyncHandler');
const { getRequestMeta } = require('../utils/requestMeta');
const { successResponse } = require('../utils/response');

const listDrivers = asyncHandler(async (req, res) => {
  const result = await adminDriverService.listDrivers(req.query);

  return successResponse({
    res,
    message: 'Admin drivers fetched successfully.',
    data: result,
  });
});

const createDriver = asyncHandler(async (req, res) => {
  const result = await adminDriverService.createDriver(req.body, {
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    statusCode: 201,
    message: 'Driver created successfully.',
    data: result,
  });
});

const getDriverDetails = asyncHandler(async (req, res) => {
  const result = await adminDriverService.getDriverDetails(req.params.driverId);

  return successResponse({
    res,
    message: 'Admin driver details fetched successfully.',
    data: result,
  });
});

const updateDriver = asyncHandler(async (req, res) => {
  const result = await adminDriverService.updateDriver(
    req.params.driverId,
    req.body,
    {
      actorUserId: req.user.id,
      requestMeta: getRequestMeta(req),
    },
  );

  return successResponse({
    res,
    message: 'Driver updated successfully.',
    data: result,
  });
});

const activateDriver = asyncHandler(async (req, res) => {
  const result = await adminDriverService.activateDriver(req.params.driverId, {
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Driver activated successfully.',
    data: result,
  });
});

const deactivateDriver = asyncHandler(async (req, res) => {
  const result = await adminDriverService.deactivateDriver(req.params.driverId, {
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Driver deactivated successfully.',
    data: result,
  });
});

module.exports = {
  activateDriver,
  createDriver,
  deactivateDriver,
  getDriverDetails,
  listDrivers,
  updateDriver,
};
