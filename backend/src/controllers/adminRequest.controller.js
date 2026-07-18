const adminRequestService = require('../services/adminRequest.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const getRequestMeta = (req) => ({
  ipAddress: req.ip,
  userAgent: req.get('user-agent'),
});

const listReports = asyncHandler(async (req, res) => {
  const result = await adminRequestService.listReports(req.query);

  return successResponse({
    res,
    message: 'Admin reports fetched successfully.',
    data: result,
  });
});

const getReportDetails = asyncHandler(async (req, res) => {
  const result = await adminRequestService.getReportDetails(req.params.reportId);

  return successResponse({
    res,
    message: 'Admin report details fetched successfully.',
    data: result,
  });
});

const updateReportStatus = asyncHandler(async (req, res) => {
  const result = await adminRequestService.updateReportStatus({
    reportId: req.params.reportId,
    reportStatus: req.body.reportStatus,
    resolutionNotes: req.body.resolutionNotes,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Report status updated successfully.',
    data: result,
  });
});

const listFuelRequests = asyncHandler(async (req, res) => {
  const result = await adminRequestService.listFuelRequests(req.query);

  return successResponse({
    res,
    message: 'Admin fuel requests fetched successfully.',
    data: result,
  });
});

const getFuelRequestDetails = asyncHandler(async (req, res) => {
  const result = await adminRequestService.getFuelRequestDetails(
    req.params.fuelRequestId,
  );

  return successResponse({
    res,
    message: 'Admin fuel request details fetched successfully.',
    data: result,
  });
});

const approveFuelRequest = asyncHandler(async (req, res) => {
  const result = await adminRequestService.approveFuelRequest({
    fuelRequestId: req.params.fuelRequestId,
    reviewNotes: req.body.reviewNotes,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Fuel request approved successfully.',
    data: result,
  });
});

const rejectFuelRequest = asyncHandler(async (req, res) => {
  const result = await adminRequestService.rejectFuelRequest({
    fuelRequestId: req.params.fuelRequestId,
    reviewNotes: req.body.reviewNotes,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Fuel request rejected successfully.',
    data: result,
  });
});

const markFuelRequestPaid = asyncHandler(async (req, res) => {
  const result = await adminRequestService.markFuelRequestPaid({
    fuelRequestId: req.params.fuelRequestId,
    reviewNotes: req.body.reviewNotes,
    actorUserId: req.user.id,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Fuel request marked paid successfully.',
    data: result,
  });
});

module.exports = {
  approveFuelRequest,
  getFuelRequestDetails,
  getReportDetails,
  listFuelRequests,
  listReports,
  markFuelRequestPaid,
  rejectFuelRequest,
  updateReportStatus,
};
