const adminShipmentService = require('../services/adminShipment.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const getRequestMeta = (req) => ({
  ipAddress: req.ip,
  userAgent: req.get('user-agent'),
});

const listShipments = asyncHandler(async (req, res) => {
  const result = await adminShipmentService.listShipments(req.query);

  return successResponse({
    res,
    message: 'Admin shipments fetched successfully.',
    data: result,
  });
});

const getShipmentDetails = asyncHandler(async (req, res) => {
  const result = await adminShipmentService.getShipmentDetails(
    req.params.shipmentId,
  );

  return successResponse({
    res,
    message: 'Admin shipment details fetched successfully.',
    data: result,
  });
});

const approveShipment = asyncHandler(async (req, res) => {
  const result = await adminShipmentService.approveShipment({
    shipmentId: req.params.shipmentId,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
    notes: req.body.notes,
  });

  return successResponse({
    res,
    message: 'Shipment approved successfully.',
    data: result,
  });
});

const rejectShipment = asyncHandler(async (req, res) => {
  const result = await adminShipmentService.rejectShipment({
    shipmentId: req.params.shipmentId,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
    reason: req.body.reason,
  });

  return successResponse({
    res,
    message: 'Shipment rejected successfully.',
    data: result,
  });
});

const cancelShipment = asyncHandler(async (req, res) => {
  const result = await adminShipmentService.cancelShipment({
    shipmentId: req.params.shipmentId,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
    reason: req.body.reason,
  });

  return successResponse({
    res,
    message: 'Shipment cancelled successfully.',
    data: result,
  });
});

const reassignShipment = asyncHandler(async (req, res) => {
  const result = await adminShipmentService.reassignShipment({
    shipmentId: req.params.shipmentId,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
    driverId: req.body.driverId,
    vehicleId: req.body.vehicleId,
    notes: req.body.notes,
  });

  return successResponse({
    res,
    message: 'Shipment reassigned successfully.',
    data: result,
  });
});

module.exports = {
  approveShipment,
  cancelShipment,
  getShipmentDetails,
  listShipments,
  reassignShipment,
  rejectShipment,
};
