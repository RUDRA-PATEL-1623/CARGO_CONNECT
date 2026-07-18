const express = require('express');

const adminAssignmentController = require('../controllers/adminAssignment.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  createAssignmentValidator,
  replaceAssignmentValidator,
  validateAssignmentConflictsValidator,
} = require('../validators/adminAssignment.validator');

const router = express.Router();

router.use(requireAuth, requireAdmin);

/**
 * @route POST /api/v1/admin/assignments/validate-conflicts
 * @description Validate shipment, driver, and vehicle assignment conflicts without mutating data.
 */
router.post(
  '/validate-conflicts',
  validateAssignmentConflictsValidator,
  validateRequest,
  adminAssignmentController.validateConflicts,
);

/**
 * @route POST /api/v1/admin/assignments
 * @description Assign driver and vehicle to an approved shipment.
 */
router.post(
  '/',
  createAssignmentValidator,
  validateRequest,
  adminAssignmentController.assignShipment,
);

/**
 * @route PATCH /api/v1/admin/assignments/:assignmentId/replace
 * @description Replace driver and vehicle for an active assignment before pickup starts.
 */
router.patch(
  '/:assignmentId/replace',
  replaceAssignmentValidator,
  validateRequest,
  adminAssignmentController.replaceAssignment,
);

module.exports = router;
