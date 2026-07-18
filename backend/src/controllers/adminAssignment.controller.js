const adminAssignmentService = require('../services/adminAssignment.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const getRequestMeta = (req) => ({
  ipAddress: req.ip,
  userAgent: req.get('user-agent'),
});

const validateConflicts = asyncHandler(async (req, res) => {
  const result = await adminAssignmentService.validateConflicts(req.body);

  return successResponse({
    res,
    message: result.canAssign
      ? 'Assignment resources are available.'
      : 'Assignment conflicts found.',
    data: result,
  });
});

const assignShipment = asyncHandler(async (req, res) => {
  const result = await adminAssignmentService.assignShipment({
    shipmentId: req.body.shipmentId,
    driverId: req.body.driverId,
    vehicleId: req.body.vehicleId,
    notes: req.body.notes,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    statusCode: 201,
    message: 'Shipment assigned successfully.',
    data: result,
  });
});

const replaceAssignment = asyncHandler(async (req, res) => {
  const result = await adminAssignmentService.replaceAssignment({
    assignmentId: req.params.assignmentId,
    driverId: req.body.driverId,
    vehicleId: req.body.vehicleId,
    notes: req.body.notes,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Assignment replaced successfully.',
    data: result,
  });
});

module.exports = {
  assignShipment,
  replaceAssignment,
  validateConflicts,
};
