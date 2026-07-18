const driverTripService = require('../services/driverTrip.service');
const { cleanupUploadedFile } = require('../middleware/proofUpload.middleware');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const getRequestMeta = (req) => ({
  ipAddress: req.ip,
  userAgent: req.get('user-agent'),
});

const listAssignedTrips = asyncHandler(async (req, res) => {
  const result = await driverTripService.listAssignedTrips(req.user.id, req.query);

  return successResponse({
    res,
    message: 'Driver assigned trips fetched successfully.',
    data: result,
  });
});

const listTripHistory = asyncHandler(async (req, res) => {
  const result = await driverTripService.listTripHistory(req.user.id, req.query);

  return successResponse({
    res,
    message: 'Driver trip history fetched successfully.',
    data: result,
  });
});

const getTripDetails = asyncHandler(async (req, res) => {
  const result = await driverTripService.getTripDetails(
    req.user.id,
    req.params.assignmentId,
  );

  return successResponse({
    res,
    message: 'Driver trip details fetched successfully.',
    data: result,
  });
});

const acceptTrip = asyncHandler(async (req, res) => {
  const result = await driverTripService.acceptTrip({
    userId: req.user.id,
    assignmentId: req.params.assignmentId,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Trip accepted successfully.',
    data: result,
  });
});

const rejectTrip = asyncHandler(async (req, res) => {
  const result = await driverTripService.rejectTrip({
    userId: req.user.id,
    assignmentId: req.params.assignmentId,
    reason: req.body.reason,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Trip rejected successfully.',
    data: result,
  });
});

const getProgressPayload = (req) => ({
  notes: req.body.notes,
  locationText: req.body.locationText,
  latitude: req.body.latitude,
  longitude: req.body.longitude,
  etaMinutes: req.body.etaMinutes,
});

const getStatusUpdatePayload = (req) => ({
  ...getProgressPayload(req),
  status: req.body.status,
  delayReason: req.body.delayReason,
});

const getProofPayload = (req) => ({
  notes: req.body.notes,
  locationText: req.body.locationText,
  latitude: req.body.latitude,
  longitude: req.body.longitude,
  capturedAt: req.body.capturedAt,
});

const uploadPickupProof = asyncHandler(async (req, res) => {
  try {
    const result = await driverTripService.uploadPickupProof({
      userId: req.user.id,
      assignmentId: req.params.assignmentId,
      file: req.file,
      payload: getProofPayload(req),
      requestMeta: getRequestMeta(req),
    });

    return successResponse({
      res,
      statusCode: 201,
      message: 'Pickup proof uploaded successfully.',
      data: result,
    });
  } catch (error) {
    cleanupUploadedFile(req.file);
    throw error;
  }
});

const uploadDeliveryProof = asyncHandler(async (req, res) => {
  try {
    const result = await driverTripService.uploadDeliveryProof({
      userId: req.user.id,
      assignmentId: req.params.assignmentId,
      file: req.file,
      payload: getProofPayload(req),
      requestMeta: getRequestMeta(req),
    });

    return successResponse({
      res,
      statusCode: 201,
      message: 'Delivery proof uploaded successfully.',
      data: result,
    });
  } catch (error) {
    cleanupUploadedFile(req.file);
    throw error;
  }
});

const startTrip = asyncHandler(async (req, res) => {
  const result = await driverTripService.startTrip({
    userId: req.user.id,
    assignmentId: req.params.assignmentId,
    payload: getProgressPayload(req),
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Trip started successfully.',
    data: result,
  });
});

const markPickupCompleted = asyncHandler(async (req, res) => {
  const result = await driverTripService.markPickupCompleted({
    userId: req.user.id,
    assignmentId: req.params.assignmentId,
    payload: getProgressPayload(req),
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Pickup completed successfully.',
    data: result,
  });
});

const markInTransit = asyncHandler(async (req, res) => {
  const result = await driverTripService.markInTransit({
    userId: req.user.id,
    assignmentId: req.params.assignmentId,
    payload: getProgressPayload(req),
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: result.message || 'Trip marked in transit successfully.',
    data: result,
  });
});

const updateTripStatus = asyncHandler(async (req, res) => {
  const result = await driverTripService.updateTripStatus({
    userId: req.user.id,
    assignmentId: req.params.assignmentId,
    payload: getStatusUpdatePayload(req),
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: result.message || 'Trip status update recorded successfully.',
    data: result,
  });
});

const markDeliveryCompleted = asyncHandler(async (req, res) => {
  const result = await driverTripService.markDeliveryCompleted({
    userId: req.user.id,
    assignmentId: req.params.assignmentId,
    payload: getProgressPayload(req),
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Delivery completed successfully.',
    data: result,
  });
});

const completeTrip = asyncHandler(async (req, res) => {
  const result = await driverTripService.completeTrip({
    userId: req.user.id,
    assignmentId: req.params.assignmentId,
    payload: getProgressPayload(req),
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Trip completed successfully.',
    data: result,
  });
});

module.exports = {
  acceptTrip,
  completeTrip,
  getTripDetails,
  listTripHistory,
  listAssignedTrips,
  markDeliveryCompleted,
  markInTransit,
  markPickupCompleted,
  rejectTrip,
  startTrip,
  updateTripStatus,
  uploadDeliveryProof,
  uploadPickupProof,
};
