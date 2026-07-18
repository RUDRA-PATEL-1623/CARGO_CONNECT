const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const customerSupportController = require('../controllers/customerSupport.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  createSupportIssueValidator,
  supportIssueListValidator,
} = require('../validators/customerSupport.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.CUSTOMER));

/**
 * @route GET /api/v1/customer/support/issues
 * @description List support issues created by the authenticated customer.
 */
router.get(
  '/support/issues',
  supportIssueListValidator,
  validateRequest,
  customerSupportController.listIssues,
);

/**
 * @route POST /api/v1/customer/support/issues
 * @description Create a support issue for the authenticated customer.
 */
router.post(
  '/support/issues',
  createSupportIssueValidator,
  validateRequest,
  customerSupportController.createIssue,
);

module.exports = router;
