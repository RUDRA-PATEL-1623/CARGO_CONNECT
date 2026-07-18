const customerCheckoutService = require('../services/customerCheckout.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const getCheckout = asyncHandler(async (req, res) => {
  const result = await customerCheckoutService.buildCheckout(
    req.user.id,
    req.params.shipmentId,
  );

  return successResponse({
    res,
    message: 'Checkout details fetched successfully.',
    data: result,
  });
});

const confirmMockPayment = asyncHandler(async (req, res) => {
  const result = await customerCheckoutService.confirmMockPayment(
    req.user.id,
    req.params.shipmentId,
    req.body,
  );

  return successResponse({
    res,
    message: 'Mock payment confirmed and invoice generated successfully.',
    data: result,
  });
});

const getInvoicePreview = asyncHandler(async (req, res) => {
  const result = await customerCheckoutService.getInvoicePreview(
    req.user.id,
    req.params.invoiceId,
  );

  return successResponse({
    res,
    message: 'Invoice preview fetched successfully.',
    data: result,
  });
});

const downloadInvoicePdf = asyncHandler(async (req, res) => {
  const { buffer, filename } = await customerCheckoutService.generateInvoicePdf(
    req.user.id,
    req.params.invoiceId,
  );

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.setHeader('Content-Length', buffer.length);

  return res.status(200).send(buffer);
});

module.exports = {
  confirmMockPayment,
  downloadInvoicePdf,
  getCheckout,
  getInvoicePreview,
};
