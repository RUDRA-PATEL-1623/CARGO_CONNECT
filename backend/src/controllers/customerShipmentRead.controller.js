const customerShipmentReadService = require('../services/customerShipmentRead.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const listHistory = asyncHandler(async (req, res) => {
  const result = await customerShipmentReadService.listHistory(
    req.user.id,
    req.query,
  );

  return successResponse({
    res,
    message: 'Customer shipment history fetched successfully.',
    data: result,
  });
});

const getDetails = asyncHandler(async (req, res) => {
  const result = await customerShipmentReadService.getDetails(
    req.user.id,
    req.params.shipmentId,
  );

  return successResponse({
    res,
    message: 'Customer shipment details fetched successfully.',
    data: result,
  });
});

const getTimeline = asyncHandler(async (req, res) => {
  const result = await customerShipmentReadService.getTimeline(
    req.user.id,
    req.params.shipmentId,
  );

  return successResponse({
    res,
    message: 'Customer shipment timeline fetched successfully.',
    data: result,
  });
});

const getTracking = asyncHandler(async (req, res) => {
  const result = await customerShipmentReadService.getTracking(
    req.user.id,
    req.params.shipmentId,
  );

  return successResponse({
    res,
    message: 'Customer shipment tracking fetched successfully.',
    data: result,
  });
});

const listProofs = asyncHandler(async (req, res) => {
  const result = await customerShipmentReadService.listProofs(
    req.user.id,
    req.params.shipmentId,
    req.query,
  );

  return successResponse({
    res,
    message: 'Customer shipment proofs fetched successfully.',
    data: result,
  });
});

const getProof = asyncHandler(async (req, res) => {
  const result = await customerShipmentReadService.getProof(
    req.user.id,
    req.params.shipmentId,
    req.params.proofId,
  );

  return successResponse({
    res,
    message: 'Customer shipment proof fetched successfully.',
    data: result,
  });
});

module.exports = {
  getDetails,
  getProof,
  getTimeline,
  getTracking,
  listHistory,
  listProofs,
};
