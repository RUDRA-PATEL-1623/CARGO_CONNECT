const express = require('express');

const adminInvoiceController = require('../controllers/adminInvoice.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  invoiceIdParamValidator,
  invoiceListValidator,
} = require('../validators/adminInvoice.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/invoices
 * @description List invoices with search, status, date, category filters, and pagination.
 */
router.get(
  '/',
  invoiceListValidator,
  validateRequest,
  adminInvoiceController.listInvoices,
);

/**
 * @route GET /api/v1/admin/invoices/:invoiceId
 * @description Fetch one invoice preview with shipment, customer, and payment context.
 */
router.get(
  '/:invoiceId',
  invoiceIdParamValidator,
  validateRequest,
  adminInvoiceController.getInvoiceDetails,
);

/**
 * @route GET /api/v1/admin/invoices/:invoiceId/download
 * @description Download a locally generated invoice PDF.
 */
router.get(
  '/:invoiceId/download',
  invoiceIdParamValidator,
  validateRequest,
  adminInvoiceController.downloadInvoicePdf,
);

module.exports = router;
