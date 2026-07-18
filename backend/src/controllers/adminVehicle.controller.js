const adminVehicleService = require('../services/adminVehicle.service');
const asyncHandler = require('../utils/asyncHandler');
const { getRequestMeta } = require('../utils/requestMeta');
const { successResponse } = require('../utils/response');

const listVehicles = asyncHandler(async (req, res) => {
  const result = await adminVehicleService.listVehicles(req.query);

  return successResponse({
    res,
    message: 'Admin vehicles fetched successfully.',
    data: result,
  });
});

const createVehicle = asyncHandler(async (req, res) => {
  const result = await adminVehicleService.createVehicle(req.body, {
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    statusCode: 201,
    message: 'Vehicle created successfully.',
    data: result,
  });
});

const getVehicleDetails = asyncHandler(async (req, res) => {
  const result = await adminVehicleService.getVehicleDetails(
    req.params.vehicleId,
  );

  return successResponse({
    res,
    message: 'Admin vehicle details fetched successfully.',
    data: result,
  });
});

const updateVehicle = asyncHandler(async (req, res) => {
  const result = await adminVehicleService.updateVehicle(
    req.params.vehicleId,
    req.body,
    {
      actorUserId: req.user.id,
      requestMeta: getRequestMeta(req),
    },
  );

  return successResponse({
    res,
    message: 'Vehicle updated successfully.',
    data: result,
  });
});

const activateVehicle = asyncHandler(async (req, res) => {
  const result = await adminVehicleService.activateVehicle(req.params.vehicleId, {
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Vehicle activated successfully.',
    data: result,
  });
});

const deactivateVehicle = asyncHandler(async (req, res) => {
  const result = await adminVehicleService.deactivateVehicle(req.params.vehicleId, {
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Vehicle deactivated successfully.',
    data: result,
  });
});

module.exports = {
  activateVehicle,
  createVehicle,
  deactivateVehicle,
  getVehicleDetails,
  listVehicles,
  updateVehicle,
};
