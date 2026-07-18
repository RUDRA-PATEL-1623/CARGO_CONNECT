const adminReportService = require('../services/adminReport.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const sendReport = (reportType) => asyncHandler(async (req, res) => {
  const result = await adminReportService.getReport(reportType, req.query);

  return successResponse({
    res,
    message: `${result.title} fetched successfully.`,
    data: result,
  });
});

const sendExport = (reportType) => asyncHandler(async (req, res) => {
  const exportFile = await adminReportService.exportReport({
    reportType,
    format: req.query.format,
    filters: req.query,
  });

  res.setHeader('Content-Type', exportFile.contentType);
  res.setHeader(
    'Content-Disposition',
    `attachment; filename="${exportFile.filename}"`,
  );

  return res.status(200).send(exportFile.buffer);
});

module.exports = {
  exportDriverReport: sendExport(adminReportService.REPORT_TYPES.DRIVERS),
  exportInvoiceReport: sendExport(adminReportService.REPORT_TYPES.INVOICES),
  exportPaymentReport: sendExport(adminReportService.REPORT_TYPES.PAYMENTS),
  exportShipmentReport: sendExport(adminReportService.REPORT_TYPES.SHIPMENTS),
  exportVehicleReport: sendExport(adminReportService.REPORT_TYPES.VEHICLES),
  getDriverReport: sendReport(adminReportService.REPORT_TYPES.DRIVERS),
  getInvoiceReport: sendReport(adminReportService.REPORT_TYPES.INVOICES),
  getPaymentReport: sendReport(adminReportService.REPORT_TYPES.PAYMENTS),
  getShipmentReport: sendReport(adminReportService.REPORT_TYPES.SHIPMENTS),
  getVehicleReport: sendReport(adminReportService.REPORT_TYPES.VEHICLES),
};
