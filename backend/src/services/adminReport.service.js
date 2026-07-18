const adminReportModel = require('../models/adminReport.model');
const reportExportService = require('./reportExport.service');
const AppError = require('../utils/appError');

const EXPORT_LIMIT = 5000;

const REPORT_TYPES = Object.freeze({
  SHIPMENTS: 'shipments',
  DRIVERS: 'drivers',
  VEHICLES: 'vehicles',
  PAYMENTS: 'payments',
  INVOICES: 'invoices',
});

const REPORT_TITLES = Object.freeze({
  [REPORT_TYPES.SHIPMENTS]: 'Shipment Report',
  [REPORT_TYPES.DRIVERS]: 'Driver Report',
  [REPORT_TYPES.VEHICLES]: 'Vehicle Report',
  [REPORT_TYPES.PAYMENTS]: 'Payment Report',
  [REPORT_TYPES.INVOICES]: 'Invoice Report',
});

const reportModelByType = Object.freeze({
  [REPORT_TYPES.SHIPMENTS]: adminReportModel.getShipmentReport,
  [REPORT_TYPES.DRIVERS]: adminReportModel.getDriverReport,
  [REPORT_TYPES.VEHICLES]: adminReportModel.getVehicleReport,
  [REPORT_TYPES.PAYMENTS]: adminReportModel.getPaymentReport,
  [REPORT_TYPES.INVOICES]: adminReportModel.getInvoiceReport,
});

const column = (label, key) => ({
  label,
  value: (row) => row[key],
});

const REPORT_COLUMNS = Object.freeze({
  [REPORT_TYPES.SHIPMENTS]: [
    column('Shipment Code', 'shipmentCode'),
    column('Customer', 'customerName'),
    column('Category', 'categoryName'),
    column('Status', 'shipmentStatus'),
    column('Payment Status', 'paymentStatus'),
    column('Pickup City', 'pickupCity'),
    column('Delivery City', 'deliveryCity'),
    column('Estimated Price', 'estimatedPrice'),
    column('Created At', 'createdAt'),
  ],
  [REPORT_TYPES.DRIVERS]: [
    column('Driver Code', 'driverCode'),
    column('Driver Name', 'driverName'),
    column('Driver Status', 'driverStatus'),
    column('Availability', 'availabilityStatus'),
    column('License Number', 'licenseNumber'),
    column('Assigned Trips', 'assignedTripsInRange'),
    column('Completed Trips', 'completedAssignmentsInRange'),
    column('Rating', 'rating'),
  ],
  [REPORT_TYPES.VEHICLES]: [
    column('Vehicle Number', 'vehicleNumber'),
    column('Registration', 'registrationNumber'),
    column('Type', 'vehicleType'),
    column('Availability', 'availabilityStatus'),
    column('Assigned Driver', 'assignedDriverName'),
    column('Capacity Kg', 'capacityKg'),
    column('Assigned Trips', 'assignedTripsInRange'),
    column('Service Due', 'serviceDueDate'),
  ],
  [REPORT_TYPES.PAYMENTS]: [
    column('Payment Code', 'paymentCode'),
    column('Shipment Code', 'shipmentCode'),
    column('Customer', 'customerName'),
    column('Category', 'categoryName'),
    column('Method', 'paymentMethod'),
    column('Status', 'paymentStatus'),
    column('Total Amount', 'totalAmount'),
    column('Created At', 'createdAt'),
  ],
  [REPORT_TYPES.INVOICES]: [
    column('Invoice Number', 'invoiceNumber'),
    column('Shipment Code', 'shipmentCode'),
    column('Customer', 'customerName'),
    column('Category', 'categoryName'),
    column('Invoice Status', 'invoiceStatus'),
    column('Payment Status', 'paymentStatus'),
    column('Total Amount', 'totalAmount'),
    column('Issued At', 'issuedAt'),
  ],
});

const allowedReportTypes = Object.values(REPORT_TYPES);

const normalizePagination = ({ page = 1, limit = 10 } = {}, exportMode = false) => {
  if (exportMode) {
    return {
      page: 1,
      limit: EXPORT_LIMIT,
      offset: 0,
    };
  }

  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(100, Math.max(1, Number(limit) || 10));

  return {
    page: safePage,
    limit: safeLimit,
    offset: (safePage - 1) * safeLimit,
  };
};

const normalizeFilters = (filters = {}) => {
  const {
    format,
    page,
    limit,
    ...reportFilters
  } = filters;

  return reportFilters;
};

const assertReportType = (reportType) => {
  if (!allowedReportTypes.includes(reportType)) {
    throw new AppError('Report type is not supported', 404);
  }
};

const getReport = async (reportType, filters = {}, options = {}) => {
  assertReportType(reportType);

  const exportMode = Boolean(options.exportMode);
  const pagination = normalizePagination(filters, exportMode);
  const reportFilters = normalizeFilters(filters);
  const reportData = await reportModelByType[reportType]({
    filters: reportFilters,
    pagination,
  });

  return {
    reportType,
    title: REPORT_TITLES[reportType],
    generatedAt: new Date().toISOString(),
    filters: {
      ...reportFilters,
      dateFrom: reportFilters.dateFrom || null,
      dateTo: reportFilters.dateTo || null,
      status: reportFilters.status || null,
      categoryId: reportFilters.categoryId || null,
      categoryCode: reportFilters.categoryCode || null,
    },
    summary: {
      dateWise: reportData.dateWise,
      statusWise: reportData.statusWise,
      categoryWise: reportData.categoryWise,
      methodWise: reportData.methodWise || null,
    },
    rows: reportData.rows,
    meta: {
      total: reportData.total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(reportData.total / pagination.limit),
      hasMore: pagination.page * pagination.limit < reportData.total,
      exportLimit: exportMode ? EXPORT_LIMIT : null,
    },
    emptyState:
      reportData.rows.length === 0
        ? {
            title: 'No report data',
            message: 'Try changing the date, status, category, or search filters.',
          }
        : null,
  };
};

const buildExportFilename = (reportType, format) => {
  const datePart = new Date().toISOString().slice(0, 10);
  return `cargoconnect-${reportType}-report-${datePart}.${format}`;
};

const exportReport = async ({ reportType, format, filters = {} }) => {
  assertReportType(reportType);

  const report = await getReport(reportType, filters, {
    exportMode: true,
  });
  const columns = REPORT_COLUMNS[reportType];

  if (format === 'csv') {
    return {
      buffer: reportExportService.buildCsv({
        columns,
        rows: report.rows,
      }),
      contentType: 'text/csv; charset=utf-8',
      filename: buildExportFilename(reportType, 'csv'),
    };
  }

  if (format === 'pdf') {
    return {
      buffer: await reportExportService.generatePdf({
        title: report.title,
        filters: report.filters,
        summary: report.summary,
        columns,
        rows: report.rows,
      }),
      contentType: 'application/pdf',
      filename: buildExportFilename(reportType, 'pdf'),
    };
  }

  throw new AppError('Export format must be csv or pdf', 422);
};

module.exports = {
  REPORT_TYPES,
  allowedReportTypes,
  exportReport,
  getReport,
};
