const express = require('express');

const adminCustomerController = require('../controllers/adminCustomer.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  customerIdParamValidator,
  customerListValidator,
  deactivateCustomerValidator,
} = require('../validators/adminCustomer.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route GET /api/v1/admin/customers
 * @description List customers with search, status, location, date filters, and pagination.
 */
router.get(
  '/',
  customerListValidator,
  validateRequest,
  adminCustomerController.listCustomers,
);

/**
 * @route GET /api/v1/admin/customers/:customerId
 * @description Fetch customer details and recent shipments.
 */
router.get(
  '/:customerId',
  customerIdParamValidator,
  validateRequest,
  adminCustomerController.getCustomerDetails,
);

/**
 * @route PATCH /api/v1/admin/customers/:customerId/activate
 * @description Activate a customer login and profile.
 */
router.patch(
  '/:customerId/activate',
  customerIdParamValidator,
  validateRequest,
  adminCustomerController.activateCustomer,
);

/**
 * @route PATCH /api/v1/admin/customers/:customerId/deactivate
 * @description Deactivate a customer login and profile.
 */
router.patch(
  '/:customerId/deactivate',
  deactivateCustomerValidator,
  validateRequest,
  adminCustomerController.deactivateCustomer,
);

module.exports = router;
