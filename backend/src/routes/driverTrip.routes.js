const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const driverTripController = require('../controllers/driverTrip.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { uploadProofFile } = require('../middleware/proofUpload.middleware');
const { requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  acceptTripValidator,
  assignedTripListValidator,
  assignmentIdParamValidator,
  proofUploadValidator,
  rejectTripValidator,
  tripProgressValidator,
  tripStatusUpdateValidator,
} = require('../validators/driverTrip.validator');

const router = express.Router();

router.use(requireAuth, requireRoles(USER_ROLES.DRIVER));

/**
 * @route GET /api/v1/driver/trips
 * @description List trips assigned to the authenticated driver.
 */
router.get(
  '/trips',
  assignedTripListValidator,
  validateRequest,
  driverTripController.listAssignedTrips,
);

/**
 * @route GET /api/v1/driver/trips/history
 * @description List completed, rejected, or cancelled trips for the authenticated driver.
 */
router.get(
  '/trips/history',
  assignedTripListValidator,
  validateRequest,
  driverTripController.listTripHistory,
);

/**
 * @route GET /api/v1/driver/trips/:assignmentId
 * @description Fetch one driver-owned trip assignment with timeline and proof summary.
 */
router.get(
  '/trips/:assignmentId',
  assignmentIdParamValidator,
  validateRequest,
  driverTripController.getTripDetails,
);

/**
 * @route POST /api/v1/driver/trips/:assignmentId/proofs/pickup
 * @description Upload pickup proof image metadata for a driver-owned trip.
 */
router.post(
  '/trips/:assignmentId/proofs/pickup',
  uploadProofFile,
  proofUploadValidator,
  validateRequest,
  driverTripController.uploadPickupProof,
);

/**
 * @route POST /api/v1/driver/trips/:assignmentId/proofs/delivery
 * @description Upload delivery proof image metadata for a driver-owned trip.
 */
router.post(
  '/trips/:assignmentId/proofs/delivery',
  uploadProofFile,
  proofUploadValidator,
  validateRequest,
  driverTripController.uploadDeliveryProof,
);

/**
 * @route PATCH /api/v1/driver/trips/:assignmentId/accept
 * @description Accept a newly assigned trip.
 */
router.patch(
  '/trips/:assignmentId/accept',
  acceptTripValidator,
  validateRequest,
  driverTripController.acceptTrip,
);

/**
 * @route PATCH /api/v1/driver/trips/:assignmentId/reject
 * @description Reject a newly assigned trip with a required reason.
 */
router.patch(
  '/trips/:assignmentId/reject',
  rejectTripValidator,
  validateRequest,
  driverTripController.rejectTrip,
);

/**
 * @route PATCH /api/v1/driver/trips/:assignmentId/start
 * @description Start an accepted trip.
 */
router.patch(
  '/trips/:assignmentId/start',
  tripProgressValidator,
  validateRequest,
  driverTripController.startTrip,
);

/**
 * @route PATCH /api/v1/driver/trips/:assignmentId/pickup-completed
 * @description Mark pickup as completed after the trip has started.
 */
router.patch(
  '/trips/:assignmentId/pickup-completed',
  tripProgressValidator,
  validateRequest,
  driverTripController.markPickupCompleted,
);

/**
 * @route PATCH /api/v1/driver/trips/:assignmentId/in-transit
 * @description Mark picked-up shipment as in transit.
 */
router.patch(
  '/trips/:assignmentId/in-transit',
  tripProgressValidator,
  validateRequest,
  driverTripController.markInTransit,
);

/**
 * @route PATCH /api/v1/driver/trips/:assignmentId/status-update
 * @description Record an in-transit ETA, delay, or issue update without skipping shipment status.
 */
router.patch(
  '/trips/:assignmentId/status-update',
  tripStatusUpdateValidator,
  validateRequest,
  driverTripController.updateTripStatus,
);

/**
 * @route PATCH /api/v1/driver/trips/:assignmentId/delivery-completed
 * @description Mark in-transit shipment as delivered.
 */
router.patch(
  '/trips/:assignmentId/delivery-completed',
  tripProgressValidator,
  validateRequest,
  driverTripController.markDeliveryCompleted,
);

/**
 * @route PATCH /api/v1/driver/trips/:assignmentId/complete
 * @description Complete a delivered trip.
 */
router.patch(
  '/trips/:assignmentId/complete',
  tripProgressValidator,
  validateRequest,
  driverTripController.completeTrip,
);

module.exports = router;
