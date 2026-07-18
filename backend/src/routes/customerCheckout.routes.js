const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const customerCheckoutController = require('../controllers/customerCheckout.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  invoiceIdParamValidator,
  mockPaymentConfirmValidator,
  shipmentIdParamValidator,
} = require('../validators/customerCheckout.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.CUSTOMER));

/**
 * @route GET /api/v1/customer/shipments/:shipmentId/checkout
 * @description Fetch checkout details, price breakdown, and existing payment/invoice state.
 */
router.get(
  '/shipments/:shipmentId/checkout',
  shipmentIdParamValidator,
  validateRequest,
  customerCheckoutController.getCheckout,
);

/**
 * @route POST /api/v1/customer/shipments/:shipmentId/checkout/mock-payment
 * @description Confirm mock payment, create payment record, and generate invoice record.
 */
router.post(
  '/shipments/:shipmentId/checkout/mock-payment',
  mockPaymentConfirmValidator,
  validateRequest,
  customerCheckoutController.confirmMockPayment,
);

/**
 * @route GET /api/v1/customer/invoices/:invoiceId
 * @description Fetch customer-owned invoice preview details.
 */
router.get(
  '/invoices/:invoiceId',
  invoiceIdParamValidator,
  validateRequest,
  customerCheckoutController.getInvoicePreview,
);

/**
 * @route GET /api/v1/customer/invoices/:invoiceId/download
 * @description Generate and download a customer-owned invoice PDF.
 */
router.get(
  '/invoices/:invoiceId/download',
  invoiceIdParamValidator,
  validateRequest,
  customerCheckoutController.downloadInvoicePdf,
);

module.exports = router;
