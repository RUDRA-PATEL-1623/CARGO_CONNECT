const adminInvoiceModel = require('../models/adminInvoice.model');
const invoicePdfService = require('./invoicePdf.service');
const AppError = require('../utils/appError');

const normalizePagination = ({ page = 1, limit = 10 } = {}) => {
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(100, Math.max(1, Number(limit) || 10));

  return {
    page: safePage,
    limit: safeLimit,
    offset: (safePage - 1) * safeLimit,
  };
};

const withDownloadUrl = (invoice) => {
  if (!invoice) {
    return null;
  }

  return {
    ...invoice,
    downloadUrl: `/api/v1/admin/invoices/${invoice.id}/download`,
  };
};

const buildInvoicePreview = (invoice) => ({
  company: {
    name: 'CargoConnect',
    email: 'billing@cargoconnect.local',
    address: 'CargoConnect Logistics HQ, India',
  },
  invoice: withDownloadUrl(invoice),
  shipment: {
    id: invoice.shipmentId,
    shipmentCode: invoice.shipmentCode,
    categoryName: invoice.categoryName,
    pickupAddress: invoice.pickupAddress,
    pickupCity: invoice.pickupCity,
    pickupState: invoice.pickupState,
    pickupPostalCode: invoice.pickupPostalCode,
    deliveryAddress: invoice.deliveryAddress,
    deliveryCity: invoice.deliveryCity,
    deliveryState: invoice.deliveryState,
    deliveryPostalCode: invoice.deliveryPostalCode,
    packageType: invoice.packageType,
    packageWeightKg: invoice.packageWeightKg,
    vehiclePreference: invoice.vehiclePreference,
    receiverName: invoice.receiverName,
    receiverPhone: invoice.receiverPhone,
    shipmentStatus: invoice.shipmentStatus,
  },
  payment: invoice.paymentId
    ? {
        id: invoice.paymentId,
        paymentCode: invoice.paymentCode,
        paymentMethod: invoice.paymentMethod,
        paymentStatus: invoice.paymentStatus,
        transactionReference: invoice.transactionReference,
      }
    : null,
});

const listInvoices = async (filters = {}) => {
  const pagination = normalizePagination(filters);
  const { rows, total } = await adminInvoiceModel.listInvoices({
    filters,
    pagination,
  });

  return {
    invoices: rows.map(withDownloadUrl),
    meta: {
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(total / pagination.limit),
      hasMore: pagination.page * pagination.limit < total,
    },
    emptyState:
      rows.length === 0
        ? {
            title: 'No invoices found',
            message: 'Try changing search, status, date, or category filters.',
          }
        : null,
  };
};

const getInvoiceDetails = async (invoiceId) => {
  const invoice = await adminInvoiceModel.findById(invoiceId);

  if (!invoice) {
    throw new AppError('Invoice was not found', 404);
  }

  return buildInvoicePreview(invoice);
};

const downloadInvoicePdf = async (invoiceId) => {
  if (!invoicePdfService.generateInvoicePdf) {
    throw new AppError('Invoice PDF generation is unavailable in this local backend.', 501);
  }

  const preview = await getInvoiceDetails(invoiceId);

  if (!preview.payment) {
    throw new AppError('Paid payment record is required for invoice PDF', 422);
  }

  const buffer = await invoicePdfService.generateInvoicePdf(preview);

  return {
    buffer,
    filename: `${preview.invoice.invoiceNumber}.pdf`,
  };
};

module.exports = {
  downloadInvoicePdf,
  getInvoiceDetails,
  listInvoices,
};
