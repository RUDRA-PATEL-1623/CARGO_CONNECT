const adminInvoiceService = require('../services/adminInvoice.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const listInvoices = asyncHandler(async (req, res) => {
  const result = await adminInvoiceService.listInvoices(req.query);

  return successResponse({
    res,
    message: 'Admin invoices fetched successfully.',
    data: result,
  });
});

const getInvoiceDetails = asyncHandler(async (req, res) => {
  const result = await adminInvoiceService.getInvoiceDetails(req.params.invoiceId);

  return successResponse({
    res,
    message: 'Admin invoice details fetched successfully.',
    data: result,
  });
});

const downloadInvoicePdf = asyncHandler(async (req, res) => {
  const pdf = await adminInvoiceService.downloadInvoicePdf(req.params.invoiceId);

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `attachment; filename="${pdf.filename}"`);

  return res.status(200).send(pdf.buffer);
});

module.exports = {
  downloadInvoicePdf,
  getInvoiceDetails,
  listInvoices,
};
