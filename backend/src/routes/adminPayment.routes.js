const express = require('express');

const adminPaymentController = require('../controllers/adminPayment.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  paymentIdParamValidator,
  paymentListValidator,
} = require('../validators/adminPayment.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/payments
 * @description List payments with search, method/status, date, category filters, and pagination.
 */
router.get(
  '/',
  paymentListValidator,
  validateRequest,
  adminPaymentController.listPayments,
);

/**
 * @route GET /api/v1/admin/payments/:paymentId
 * @description Fetch one payment with shipment, customer, and invoice context.
 */
router.get(
  '/:paymentId',
  paymentIdParamValidator,
  validateRequest,
  adminPaymentController.getPaymentDetails,
);

module.exports = router;
