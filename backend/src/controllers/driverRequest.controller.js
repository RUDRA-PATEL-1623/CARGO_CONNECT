const { cleanupUploadedFile } = require('../middleware/requestUpload.middleware');
const driverRequestService = require('../services/driverRequest.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const getRequestMeta = (req) => ({
  ipAddress: req.ip,
  userAgent: req.get('user-agent'),
});

const getLocationPayload = (req) => ({
  locationText: req.body.locationText,
  latitude: req.body.latitude,
  longitude: req.body.longitude,
});

const createEmergencyReport = asyncHandler(async (req, res) => {
  try {
    const result = await driverRequestService.createEmergencyReport({
      userId: req.user.id,
      reportType: req.body.reportType,
      severity: req.body.severity,
      description: req.body.description,
      assignmentId: req.body.assignmentId,
      vehicleId: req.body.vehicleId,
      attachmentFile: req.file,
      ...getLocationPayload(req),
      requestMeta: getRequestMeta(req),
    });

    return successResponse({
      res,
      statusCode: 201,
      message: 'Emergency report submitted successfully.',
      data: result,
    });
  } catch (error) {
    cleanupUploadedFile(req.file);
    throw error;
  }
});

const createBreakdownReport = asyncHandler(async (req, res) => {
  try {
    const result = await driverRequestService.createBreakdownReport({
      userId: req.user.id,
      issueType: req.body.issueType,
      severity: req.body.severity,
      description: req.body.description,
      assignmentId: req.body.assignmentId,
      vehicleId: req.body.vehicleId,
      attachmentFile: req.file,
      ...getLocationPayload(req),
      requestMeta: getRequestMeta(req),
    });

    return successResponse({
      res,
      statusCode: 201,
      message: 'Breakdown report submitted successfully.',
      data: result,
    });
  } catch (error) {
    cleanupUploadedFile(req.file);
    throw error;
  }
});

const listReports = asyncHandler(async (req, res) => {
  const result = await driverRequestService.listReports(req.user.id, req.query);

  return successResponse({
    res,
    message: 'Driver reports fetched successfully.',
    data: result,
  });
});

const createFuelRequest = asyncHandler(async (req, res) => {
  const result = await driverRequestService.createFuelRequest({
    userId: req.user.id,
    assignmentId: req.body.assignmentId,
    vehicleId: req.body.vehicleId,
    fuelAmountLiters: req.body.fuelAmountLiters,
    billAmount: req.body.billAmount,
    fuelStation: req.body.fuelStation,
    notes: req.body.notes,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    statusCode: 201,
    message: 'Fuel request submitted successfully.',
    data: result,
  });
});

const listFuelRequests = asyncHandler(async (req, res) => {
  const result = await driverRequestService.listFuelRequests(req.user.id, req.query);

  return successResponse({
    res,
    message: 'Driver fuel requests fetched successfully.',
    data: result,
  });
});

const uploadFuelBill = asyncHandler(async (req, res) => {
  try {
    const result = await driverRequestService.uploadFuelBill({
      userId: req.user.id,
      fuelRequestId: req.params.fuelRequestId,
      billFile: req.file,
      notes: req.body.notes,
      requestMeta: getRequestMeta(req),
    });

    return successResponse({
      res,
      message: 'Fuel bill uploaded successfully.',
      data: result,
    });
  } catch (error) {
    cleanupUploadedFile(req.file);
    throw error;
  }
});

module.exports = {
  createBreakdownReport,
  createEmergencyReport,
  createFuelRequest,
  listFuelRequests,
  listReports,
  uploadFuelBill,
};
