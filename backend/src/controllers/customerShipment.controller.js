const customerShipmentService = require('../services/customerShipment.service');
const customerCheckoutService = require('../services/customerCheckout.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const calculateEstimate = asyncHandler(async (req, res) => {
  const result = await customerShipmentService.calculateCustomerPriceEstimate(
    req.user.id,
    req.body,
  );

  return successResponse({
    res,
    message: 'Shipment price estimate calculated successfully.',
    data: result,
  });
});

const createShipmentRequest = asyncHandler(async (req, res) => {
  const result = await customerShipmentService.createShipmentRequest(
    req.user.id,
    req.body,
  );

  return successResponse({
    res,
    statusCode: 201,
    message: 'Shipment request created successfully.',
    data: result,
  });
});

const getShipmentSummary = asyncHandler(async (req, res) => {
  const result = await customerShipmentService.getShipmentSummary(
    req.user.id,
    req.params.shipmentId,
  );

  return successResponse({
    res,
    message: 'Shipment summary fetched successfully.',
    data: result,
  });
});

const placeOrder = asyncHandler(async (req, res) => {
  const result = await customerCheckoutService.confirmMockPayment(
    req.user.id,
    req.params.shipmentId,
    req.body,
  );

  return successResponse({
    res,
    message: 'Shipment order placed successfully.',
    data: result,
  });
});

module.exports = {
  calculateEstimate,
  createShipmentRequest,
  getShipmentSummary,
  placeOrder,
};
