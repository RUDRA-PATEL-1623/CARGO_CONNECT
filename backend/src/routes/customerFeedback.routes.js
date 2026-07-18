const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const customerFeedbackController = require('../controllers/customerFeedback.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  feedbackListValidator,
  submitFeedbackValidator,
} = require('../validators/customerFeedback.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.CUSTOMER));

/**
 * @route GET /api/v1/customer/feedback
 * @description List feedback submitted by the authenticated customer.
 */
router.get(
  '/feedback',
  feedbackListValidator,
  validateRequest,
  customerFeedbackController.listFeedback,
);

/**
 * @route POST /api/v1/customer/feedback
 * @description Submit shipment feedback for the authenticated customer.
 */
router.post(
  '/feedback',
  submitFeedbackValidator,
  validateRequest,
  customerFeedbackController.submitFeedback,
);

module.exports = router;
