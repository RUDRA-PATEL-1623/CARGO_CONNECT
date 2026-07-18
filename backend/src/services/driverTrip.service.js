const { getPool } = require('../config/database');
const { NOTIFICATION_TYPES } = require('../constants/notification.constants');
const driverModel = require('../models/driver.model');
const driverTripModel = require('../models/driverTrip.model');
const auditLogModel = require('../models/auditLog.model');
const notificationService = require('./notification.service');
const AppError = require('../utils/appError');

const DRIVER_STATUS_FLOW = [
  { status: 'assigned', label: 'Assigned' },
  { status: 'accepted', label: 'Accepted' },
  { status: 'started', label: 'Started' },
  { status: 'pickup_completed', label: 'Pickup Completed' },
  { status: 'in_transit', label: 'In Transit' },
  { status: 'delivered', label: 'Delivered' },
  { status: 'completed', label: 'Completed' },
];

const PROGRESS_TRANSITIONS = Object.freeze({
  start: {
    fromAssignmentStatus: 'accepted',
    toAssignmentStatus: 'started',
    fromShipmentStatus: 'accepted',
    toShipmentStatus: 'accepted',
    logStatus: 'started',
    logTitle: 'Trip started',
    defaultDescription: 'Driver started the accepted trip.',
    auditAction: 'driver.trip.started',
    message: 'Trip started successfully.',
  },
  pickupCompleted: {
    fromAssignmentStatus: 'started',
    toAssignmentStatus: 'pickup_completed',
    fromShipmentStatus: 'accepted',
    toShipmentStatus: 'pickup_completed',
    logStatus: 'pickup_completed',
    logTitle: 'Pickup completed',
    defaultDescription: 'Driver confirmed pickup completion.',
    auditAction: 'driver.trip.pickup_completed',
    message: 'Pickup completed successfully.',
  },
  inTransit: {
    fromAssignmentStatus: 'pickup_completed',
    toAssignmentStatus: 'in_transit',
    fromShipmentStatus: 'pickup_completed',
    toShipmentStatus: 'in_transit',
    requiresProofType: 'pickup',
    logStatus: 'in_transit',
    logTitle: 'Trip marked in transit',
    defaultDescription: 'Shipment is now in transit.',
    auditAction: 'driver.trip.in_transit',
    message: 'Trip marked in transit successfully.',
  },
  deliveryCompleted: {
    fromAssignmentStatus: 'in_transit',
    toAssignmentStatus: 'delivered',
    fromShipmentStatus: 'in_transit',
    toShipmentStatus: 'delivered',
    requiresProofType: 'delivery',
    logStatus: 'delivered',
    logTitle: 'Delivery completed',
    defaultDescription: 'Driver confirmed delivery completion.',
    auditAction: 'driver.trip.delivered',
    message: 'Delivery completed successfully.',
  },
  complete: {
    fromAssignmentStatus: 'delivered',
    toAssignmentStatus: 'completed',
    fromShipmentStatus: 'delivered',
    toShipmentStatus: 'completed',
    requiresProofType: 'delivery',
    logStatus: 'completed',
    logTitle: 'Trip completed',
    defaultDescription: 'Driver completed the trip workflow.',
    auditAction: 'driver.trip.completed',
    message: 'Trip completed successfully.',
    markShipmentCompleted: true,
  },
});

const PROGRESS_NOTIFICATION_CONFIG = Object.freeze({
  start: {
    notificationType: NOTIFICATION_TYPES.SHIPMENT_STARTED,
    title: 'Trip started',
    message: (trip) => `Driver started shipment ${trip.shipmentCode}.`,
  },
  pickupCompleted: {
    notificationType: NOTIFICATION_TYPES.PICKUP_COMPLETED,
    title: 'Pickup completed',
    message: (trip) => `Pickup proof is complete for shipment ${trip.shipmentCode}.`,
  },
  inTransit: {
    notificationType: NOTIFICATION_TYPES.IN_TRANSIT,
    title: 'Shipment in transit',
    message: (trip) => `Shipment ${trip.shipmentCode} is now in transit.`,
  },
  deliveryCompleted: {
    notificationType: NOTIFICATION_TYPES.DELIVERED,
    title: 'Shipment delivered',
    message: (trip) => `Shipment ${trip.shipmentCode} has been delivered.`,
  },
  complete: {
    notificationType: NOTIFICATION_TYPES.COMPLETED,
    title: 'Trip completed',
    message: (trip) => `Shipment ${trip.shipmentCode} has been completed.`,
  },
});

const PROOF_UPLOAD_RULES = Object.freeze({
  pickup: {
    allowedAssignmentStatuses: ['started', 'pickup_completed'],
    endpointSuffix: 'pickup',
    auditAction: 'driver.proof.pickup_uploaded',
    message: 'Pickup proof uploaded successfully.',
  },
  delivery: {
    allowedAssignmentStatuses: ['in_transit', 'delivered'],
    endpointSuffix: 'delivery',
    auditAction: 'driver.proof.delivery_uploaded',
    message: 'Delivery proof uploaded successfully.',
  },
});

const normalizePagination = ({ page = 1, limit = 10 } = {}) => {
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(50, Math.max(1, Number(limit) || 10));

  return {
    page: safePage,
    limit: safeLimit,
    offset: (safePage - 1) * safeLimit,
  };
};

const maskPhone = (phone) => {
  if (!phone) {
    return null;
  }

  const phoneValue = String(phone);
  const visible = phoneValue.slice(-4);
  return `${'*'.repeat(Math.max(0, phoneValue.length - 4))}${visible}`;
};

const getActiveDriver = async (userId, connection = null) => {
  const driver = await driverModel.findByUserId(userId, connection);

  if (!driver || driver.driverStatus !== 'active') {
    throw new AppError('Active driver profile is required', 403);
  }

  return driver;
};

const formatTrip = (trip) => ({
  id: trip.assignmentId,
  assignmentCode: trip.assignmentCode,
  assignmentStatus: trip.assignmentStatus,
  assignedAt: trip.assignedAt,
  acceptedAt: trip.acceptedAt,
  rejectedAt: trip.rejectedAt,
  rejectionReason: trip.rejectionReason,
  startedAt: trip.startedAt,
  completedAt: trip.assignmentCompletedAt,
  shipment: {
    id: trip.shipmentId,
    shipmentCode: trip.shipmentCode,
    shipmentStatus: trip.shipmentStatus,
    paymentStatus: trip.paymentStatus,
    category: {
      id: trip.categoryId,
      code: trip.categoryCode,
      name: trip.categoryName,
      iconKey: trip.categoryIconKey,
    },
    pickup: {
      address: trip.pickupAddress,
      city: trip.pickupCity,
      state: trip.pickupState,
      postalCode: trip.pickupPostalCode,
      scheduledAt: trip.pickupDateTime,
    },
    delivery: {
      address: trip.deliveryAddress,
      city: trip.deliveryCity,
      state: trip.deliveryState,
      postalCode: trip.deliveryPostalCode,
    },
  },
  customer: {
    id: trip.customerId,
    customerCode: trip.customerCode,
    name: trip.customerName,
    phoneMasked: maskPhone(trip.customerPhone),
    emailMasked: trip.customerEmail
      ? trip.customerEmail.replace(/(^.).*(@.*$)/, '$1***$2')
      : null,
  },
  receiver: {
    name: trip.receiverName,
    phone: trip.receiverPhone,
  },
  package: {
    type: trip.packageType,
    weightKg: trip.packageWeightKg,
    dimensionsCm: {
      length: trip.packageLengthCm,
      width: trip.packageWidthCm,
      height: trip.packageHeightCm,
    },
    vehiclePreference: trip.vehiclePreference,
    isFragile: trip.isFragile,
    deliveryNotes: trip.deliveryNotes,
  },
  vehicle: {
    id: trip.vehicleId,
    vehicleNumber: trip.vehicleNumber,
    registrationNumber: trip.vehicleRegistrationNumber,
    type: trip.vehicleType,
    model: trip.vehicleModel,
    fuelType: trip.vehicleFuelType,
    capacityKg: trip.vehicleCapacityKg,
    availabilityStatus: trip.vehicleAvailabilityStatus,
  },
  routeSummary: {
    estimatedDistanceKm: trip.estimatedDistanceKm,
    estimatedDurationMinutes: trip.estimatedDurationMinutes,
    estimatedPrice: trip.estimatedPrice,
  },
  actions: {
    canAccept: trip.assignmentStatus === 'assigned' && trip.shipmentStatus === 'assigned',
    canReject: trip.assignmentStatus === 'assigned' && trip.shipmentStatus === 'assigned',
    canStart: trip.assignmentStatus === 'accepted' && trip.shipmentStatus === 'accepted',
    canMarkPickupCompleted:
      trip.assignmentStatus === 'started' && trip.shipmentStatus === 'accepted',
    canMarkInTransit:
      trip.assignmentStatus === 'pickup_completed'
      && trip.shipmentStatus === 'pickup_completed',
    canUpdateInTransit:
      trip.assignmentStatus === 'in_transit' && trip.shipmentStatus === 'in_transit',
    canMarkDeliveryCompleted:
      trip.assignmentStatus === 'in_transit' && trip.shipmentStatus === 'in_transit',
    canComplete: trip.assignmentStatus === 'delivered' && trip.shipmentStatus === 'delivered',
    canUploadPickupProof: ['started', 'pickup_completed'].includes(trip.assignmentStatus),
    canUploadDeliveryProof: ['in_transit', 'delivered'].includes(trip.assignmentStatus),
  },
});

const eventTimeByStatus = ({ trip, tripLogs }) => {
  const timestamps = new Map();

  if (trip.assignedAt) {
    timestamps.set('assigned', trip.assignedAt);
  }

  if (trip.acceptedAt) {
    timestamps.set('accepted', trip.acceptedAt);
  }

  if (trip.startedAt) {
    timestamps.set('started', trip.startedAt);
  }

  if (trip.assignmentCompletedAt) {
    timestamps.set('completed', trip.assignmentCompletedAt);
  }

  tripLogs.forEach((log) => {
    if (!timestamps.has(log.status)) {
      timestamps.set(log.status, log.eventTime);
    }
  });

  return timestamps;
};

const buildTimeline = ({ trip, tripLogs }) => {
  const currentIndex = DRIVER_STATUS_FLOW.findIndex(
    (step) => step.status === trip.assignmentStatus,
  );
  const timestamps = eventTimeByStatus({ trip, tripLogs });

  const steps = DRIVER_STATUS_FLOW.map((step, index) => {
    let state = 'pending';

    if (timestamps.has(step.status) || (currentIndex >= 0 && index < currentIndex)) {
      state = 'completed';
    }

    if (currentIndex === index) {
      state = 'current';
    }

    return {
      ...step,
      state,
      timestamp: timestamps.get(step.status) || null,
      description:
        tripLogs.find((log) => log.status === step.status)?.description || null,
    };
  });

  if (['rejected', 'cancelled'].includes(trip.assignmentStatus)) {
    steps.push({
      status: trip.assignmentStatus,
      label: trip.assignmentStatus === 'rejected' ? 'Rejected' : 'Cancelled',
      state: 'current',
      timestamp: trip.rejectedAt || trip.assignmentUpdatedAt,
      description: trip.rejectionReason || null,
    });
  }

  return {
    currentStatus: trip.assignmentStatus,
    steps,
    events: tripLogs,
  };
};

const assertTrip = (trip) => {
  if (!trip) {
    throw new AppError('Trip assignment was not found', 404);
  }
};

const assertCanAcceptOrReject = (trip) => {
  if (trip.assignmentStatus !== 'assigned') {
    throw new AppError('Only newly assigned trips can be accepted or rejected', 409, {
      assignmentStatus: trip.assignmentStatus,
    });
  }

  if (trip.shipmentStatus !== 'assigned') {
    throw new AppError('Trip cannot be updated because shipment is no longer assigned', 409, {
      shipmentStatus: trip.shipmentStatus,
    });
  }
};

const assertCanProgress = (trip, transition) => {
  if (trip.assignmentStatus !== transition.fromAssignmentStatus) {
    throw new AppError(
      `Trip must be ${transition.fromAssignmentStatus} before it can move to ${transition.toAssignmentStatus}`,
      409,
      {
        currentAssignmentStatus: trip.assignmentStatus,
        requiredAssignmentStatus: transition.fromAssignmentStatus,
        nextAssignmentStatus: transition.toAssignmentStatus,
      },
    );
  }

  if (trip.shipmentStatus !== transition.fromShipmentStatus) {
    throw new AppError(
      `Shipment must be ${transition.fromShipmentStatus} before trip can move to ${transition.toAssignmentStatus}`,
      409,
      {
        currentShipmentStatus: trip.shipmentStatus,
        requiredShipmentStatus: transition.fromShipmentStatus,
        nextShipmentStatus: transition.toShipmentStatus,
      },
    );
  }
};

const createAudit = async (
  { action, entityId, actorUserId, requestMeta, oldValues, newValues },
  connection,
) => {
  await auditLogModel.createAuditLog(
    {
      actorUserId,
      action,
      entityType: 'assignment',
      entityId,
      oldValues,
      newValues,
      ipAddress: requestMeta?.ipAddress || null,
      userAgent: requestMeta?.userAgent || null,
    },
    connection,
  );
};

const buildProgressDescription = (transition, payload = {}) => {
  const parts = [payload.notes || transition.defaultDescription];

  if (payload.etaMinutes) {
    parts.push(`ETA ${payload.etaMinutes} minutes.`);
  }

  return parts.join(' ');
};

const buildStatusUpdateDescription = (status, payload = {}) => {
  const defaultDescriptions = {
    in_transit: 'Driver shared an in-transit progress update.',
    delayed: 'Driver reported a route delay.',
    issue_reported: 'Driver reported an in-transit issue.',
  };
  const parts = [payload.notes || defaultDescriptions[status]];

  if (payload.delayReason) {
    parts.push(`Reason: ${payload.delayReason}.`);
  }

  if (payload.etaMinutes) {
    parts.push(`ETA ${payload.etaMinutes} minutes.`);
  }

  return parts.join(' ');
};

const buildNotificationContext = (trip) => ({
  customerUserId: trip.customerUserId,
  shipment: {
    id: trip.shipmentId,
    shipmentCode: trip.shipmentCode,
    shipmentStatus: trip.shipmentStatus,
  },
  assignment: {
    id: trip.assignmentId,
    assignmentCode: trip.assignmentCode,
    assignmentStatus: trip.assignmentStatus,
  },
});

const buildProofUploadEndpoint = ({ assignmentId, proofType }) => {
  const rule = PROOF_UPLOAD_RULES[proofType];
  return `/api/v1/driver/trips/${assignmentId}/proofs/${rule.endpointSuffix}`;
};

const assertCanUploadProof = (trip, proofType) => {
  const rule = PROOF_UPLOAD_RULES[proofType];

  if (!rule) {
    throw new AppError('Proof type is not supported', 400);
  }

  if (!rule.allowedAssignmentStatuses.includes(trip.assignmentStatus)) {
    throw new AppError(
      `${proofType} proof cannot be uploaded while trip status is ${trip.assignmentStatus}`,
      409,
      {
        currentAssignmentStatus: trip.assignmentStatus,
        allowedAssignmentStatuses: rule.allowedAssignmentStatuses,
      },
    );
  }
};

const assertProofExists = async ({ trip, proofType }, connection) => {
  const proof = await driverTripModel.findProofByType(
    {
      shipmentId: trip.shipmentId,
      assignmentId: trip.assignmentId,
      driverId: trip.driverId,
      proofType,
    },
    connection,
  );

  if (!proof) {
    throw new AppError(
      `${proofType} proof is required before moving trip to the next status`,
      422,
      {
        requiredProofType: proofType,
        uploadEndpoint: buildProofUploadEndpoint({
          assignmentId: trip.assignmentId,
          proofType,
        }),
      },
    );
  }

  return proof;
};

const buildFileUrl = (file) => `/uploads/proofs/${file.filename}`;

const listAssignedTrips = async (userId, filters = {}) => {
  const driver = await getActiveDriver(userId);
  const pagination = normalizePagination(filters);
  const { rows, total } = await driverTripModel.listTrips({
    driverId: driver.id,
    filters,
    pagination,
  });

  return {
    driver: {
      id: driver.id,
      driverCode: driver.driverCode,
      availabilityStatus: driver.availabilityStatus,
    },
    trips: rows.map(formatTrip),
    meta: {
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(total / pagination.limit),
      hasMore: pagination.page * pagination.limit < total,
    },
    emptyState:
      rows.length === 0
        ? {
            title: 'No assigned trips found',
            message: 'Try changing the status, date, or search filters.',
          }
        : null,
  };
};

const listTripHistory = async (userId, filters = {}) => {
  const historyFilters = { ...filters };

  if (!historyFilters.group && !historyFilters.status) {
    historyFilters.group = 'history';
  }

  return listAssignedTrips(userId, historyFilters);
};

const getTripDetails = async (userId, assignmentId) => {
  const driver = await getActiveDriver(userId);
  const trip = await driverTripModel.findTripById({
    driverId: driver.id,
    assignmentId,
  });

  assertTrip(trip);

  const [tripLogs, proofs] = await Promise.all([
    driverTripModel.listTripLogs(trip.shipmentId),
    driverTripModel.listProofs({
      shipmentId: trip.shipmentId,
      assignmentId: trip.assignmentId,
      driverId: driver.id,
    }),
  ]);

  return {
    trip: formatTrip(trip),
    timeline: buildTimeline({ trip, tripLogs }),
    proofs,
  };
};

const acceptTrip = async ({ userId, assignmentId, requestMeta }) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const driver = await getActiveDriver(userId, connection);
    const trip = await driverTripModel.findTripById(
      {
        driverId: driver.id,
        assignmentId,
      },
      connection,
    );

    assertTrip(trip);
    assertCanAcceptOrReject(trip);

    const affectedRows = await driverTripModel.updateAssignmentAccepted(
      {
        assignmentId,
        driverId: driver.id,
      },
      connection,
    );

    if (affectedRows === 0) {
      throw new AppError('Trip could not be accepted because its status changed', 409);
    }

    await driverTripModel.updateShipmentStatus(
      {
        shipmentId: trip.shipmentId,
        status: 'accepted',
      },
      connection,
    );

    await driverTripModel.updateDriverAvailability(
      {
        driverId: driver.id,
        availabilityStatus: 'busy',
      },
      connection,
    );

    await driverTripModel.createTripLog(
      {
        shipmentId: trip.shipmentId,
        assignmentId: trip.assignmentId,
        driverId: driver.id,
        vehicleId: trip.vehicleId,
        status: 'accepted',
        title: 'Trip accepted by driver',
        description: 'Driver accepted the assigned CargoConnect shipment.',
      },
      connection,
    );

    const updatedTrip = await driverTripModel.findTripById(
      {
        driverId: driver.id,
        assignmentId,
      },
      connection,
    );

    await createAudit(
      {
        action: 'driver.trip.accepted',
        entityId: trip.assignmentId,
        actorUserId: userId,
        requestMeta,
        oldValues: {
          assignmentStatus: trip.assignmentStatus,
          shipmentStatus: trip.shipmentStatus,
        },
        newValues: {
          assignmentStatus: updatedTrip.assignmentStatus,
          shipmentStatus: updatedTrip.shipmentStatus,
        },
      },
      connection,
    );

    await notificationService.notifyTripAccepted(
      buildNotificationContext(updatedTrip),
      connection,
    );
    await connection.commit();

    return {
      trip: formatTrip(updatedTrip),
      message: 'Trip accepted successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const rejectTrip = async ({ userId, assignmentId, reason, requestMeta }) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const driver = await getActiveDriver(userId, connection);
    const trip = await driverTripModel.findTripById(
      {
        driverId: driver.id,
        assignmentId,
      },
      connection,
    );

    assertTrip(trip);
    assertCanAcceptOrReject(trip);

    const affectedRows = await driverTripModel.updateAssignmentRejected(
      {
        assignmentId,
        driverId: driver.id,
        reason,
      },
      connection,
    );

    if (affectedRows === 0) {
      throw new AppError('Trip could not be rejected because its status changed', 409);
    }

    await driverTripModel.updateShipmentStatus(
      {
        shipmentId: trip.shipmentId,
        status: 'approved',
      },
      connection,
    );

    const activeDriverAssignments =
      await driverTripModel.countActiveDriverAssignments(
        {
          driverId: driver.id,
          excludedAssignmentId: trip.assignmentId,
        },
        connection,
      );

    if (activeDriverAssignments === 0) {
      await driverTripModel.updateDriverAvailability(
        {
          driverId: driver.id,
          availabilityStatus: 'available',
        },
        connection,
      );
    }

    const activeVehicleAssignments =
      await driverTripModel.countActiveVehicleAssignments(
        {
          vehicleId: trip.vehicleId,
          excludedAssignmentId: trip.assignmentId,
        },
        connection,
      );

    if (activeVehicleAssignments === 0) {
      await driverTripModel.updateVehicleAssignment(
        {
          vehicleId: trip.vehicleId,
          availabilityStatus: 'available',
          assignedDriverId: null,
        },
        connection,
      );
    }

    await driverTripModel.createTripLog(
      {
        shipmentId: trip.shipmentId,
        assignmentId: trip.assignmentId,
        driverId: driver.id,
        vehicleId: trip.vehicleId,
        status: 'rejected',
        title: 'Trip rejected by driver',
        description: reason,
      },
      connection,
    );

    const updatedTrip = await driverTripModel.findTripById(
      {
        driverId: driver.id,
        assignmentId,
      },
      connection,
    );

    await createAudit(
      {
        action: 'driver.trip.rejected',
        entityId: trip.assignmentId,
        actorUserId: userId,
        requestMeta,
        oldValues: {
          assignmentStatus: trip.assignmentStatus,
          shipmentStatus: trip.shipmentStatus,
          driverAvailabilityStatus: trip.driverAvailabilityStatus,
          vehicleAvailabilityStatus: trip.vehicleAvailabilityStatus,
        },
        newValues: {
          assignmentStatus: updatedTrip.assignmentStatus,
          shipmentStatus: updatedTrip.shipmentStatus,
          reason,
        },
      },
      connection,
    );

    await notificationService.notifyTripRejected(
      {
        ...buildNotificationContext(updatedTrip),
        reason,
      },
      connection,
    );
    await connection.commit();

    return {
      trip: formatTrip(updatedTrip),
      message: 'Trip rejected successfully and returned to dispatch queue.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const uploadProof = async ({
  userId,
  assignmentId,
  proofType,
  file,
  payload = {},
  requestMeta,
}) => {
  if (!file) {
    throw new AppError('Proof image file is required in form field "proof"', 422);
  }

  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const driver = await getActiveDriver(userId, connection);
    const trip = await driverTripModel.findTripById(
      {
        driverId: driver.id,
        assignmentId,
      },
      connection,
    );

    assertTrip(trip);
    assertCanUploadProof(trip, proofType);

    const proof = await driverTripModel.createProofUpload(
      {
        shipmentId: trip.shipmentId,
        assignmentId: trip.assignmentId,
        driverId: driver.id,
        proofType,
        fileUrl: buildFileUrl(file),
        fileName: file.originalname,
        fileMimeType: file.mimetype,
        fileSizeBytes: file.size,
        notes: payload.notes,
        locationText: payload.locationText,
        latitude: payload.latitude,
        longitude: payload.longitude,
        capturedAt: payload.capturedAt,
      },
      connection,
    );

    await createAudit(
      {
        action: PROOF_UPLOAD_RULES[proofType].auditAction,
        entityId: trip.assignmentId,
        actorUserId: userId,
        requestMeta,
        oldValues: {
          assignmentStatus: trip.assignmentStatus,
          shipmentStatus: trip.shipmentStatus,
        },
        newValues: {
          proof,
        },
      },
      connection,
    );

    await connection.commit();

    return {
      trip: formatTrip(trip),
      proof,
      message: PROOF_UPLOAD_RULES[proofType].message,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const updateTripStatus = async ({
  userId,
  assignmentId,
  payload = {},
  requestMeta,
}) => {
  const status = payload.status || (payload.delayReason ? 'delayed' : 'in_transit');
  const titleByStatus = {
    in_transit: 'In-transit update',
    delayed: 'Delay reported',
    issue_reported: 'Issue reported',
  };
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const driver = await getActiveDriver(userId, connection);
    const trip = await driverTripModel.findTripById(
      {
        driverId: driver.id,
        assignmentId,
      },
      connection,
    );

    assertTrip(trip);

    if (trip.assignmentStatus !== 'in_transit' || trip.shipmentStatus !== 'in_transit') {
      throw new AppError(
        'Trip status updates can be recorded only while the shipment is in transit',
        409,
        {
          currentAssignmentStatus: trip.assignmentStatus,
          currentShipmentStatus: trip.shipmentStatus,
          requiredStatus: 'in_transit',
        },
      );
    }

    const tripLog = await driverTripModel.createTripLog(
      {
        shipmentId: trip.shipmentId,
        assignmentId: trip.assignmentId,
        driverId: driver.id,
        vehicleId: trip.vehicleId,
        status,
        title: titleByStatus[status] || 'Trip status update',
        description: buildStatusUpdateDescription(status, payload),
        locationText: payload.locationText,
        latitude: payload.latitude,
        longitude: payload.longitude,
      },
      connection,
    );

    const updatedTrip = await driverTripModel.findTripById(
      {
        driverId: driver.id,
        assignmentId,
      },
      connection,
    );

    await createAudit(
      {
        action: `driver.trip.${status}_update`,
        entityId: trip.assignmentId,
        actorUserId: userId,
        requestMeta,
        oldValues: {
          assignmentStatus: trip.assignmentStatus,
          shipmentStatus: trip.shipmentStatus,
        },
        newValues: {
          assignmentStatus: updatedTrip.assignmentStatus,
          shipmentStatus: updatedTrip.shipmentStatus,
          etaMinutes: payload.etaMinutes || null,
          delayReason: payload.delayReason || null,
          tripLog,
        },
      },
      connection,
    );

    if (status !== 'in_transit') {
      await notificationService.notifyShipmentStatus(
        {
          ...buildNotificationContext(updatedTrip),
          notificationType: NOTIFICATION_TYPES.SYSTEM,
          title: titleByStatus[status],
          message:
            status === 'delayed'
              ? `Driver reported a delay for shipment ${updatedTrip.shipmentCode}.`
              : `Driver reported an issue for shipment ${updatedTrip.shipmentCode}.`,
        },
        connection,
      );
    }

    await connection.commit();

    return {
      trip: formatTrip(updatedTrip),
      tripLog,
      message: 'Trip status update recorded successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const updateTripProgress = async ({
  userId,
  assignmentId,
  transitionKey,
  payload = {},
  requestMeta,
}) => {
  const transition = PROGRESS_TRANSITIONS[transitionKey];

  if (!transition) {
    throw new AppError('Trip transition is not supported', 400);
  }

  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const driver = await getActiveDriver(userId, connection);
    const trip = await driverTripModel.findTripById(
      {
        driverId: driver.id,
        assignmentId,
      },
      connection,
    );

    assertTrip(trip);
    assertCanProgress(trip, transition);

    if (transition.requiresProofType) {
      await assertProofExists(
        {
          trip,
          proofType: transition.requiresProofType,
        },
        connection,
      );
    }

    const affectedRows = await driverTripModel.updateAssignmentStatus(
      {
        assignmentId,
        driverId: driver.id,
        fromStatus: transition.fromAssignmentStatus,
        toStatus: transition.toAssignmentStatus,
      },
      connection,
    );

    if (affectedRows === 0) {
      throw new AppError('Trip could not be updated because its status changed', 409);
    }

    await driverTripModel.updateShipmentStatus(
      {
        shipmentId: trip.shipmentId,
        status: transition.toShipmentStatus,
        markCompleted: Boolean(transition.markShipmentCompleted),
      },
      connection,
    );

    if (transition.toAssignmentStatus === 'started') {
      await driverTripModel.updateDriverAvailability(
        {
          driverId: driver.id,
          availabilityStatus: 'busy',
        },
        connection,
      );
    }

    if (transition.toAssignmentStatus === 'completed') {
      await driverTripModel.incrementDriverCompletedTrips(driver.id, connection);

      const activeDriverAssignments =
        await driverTripModel.countActiveDriverAssignments(
          {
            driverId: driver.id,
            excludedAssignmentId: trip.assignmentId,
          },
          connection,
        );

      if (activeDriverAssignments === 0) {
        await driverTripModel.updateDriverAvailability(
          {
            driverId: driver.id,
            availabilityStatus: 'available',
          },
          connection,
        );
      }

      const activeVehicleAssignments =
        await driverTripModel.countActiveVehicleAssignments(
          {
            vehicleId: trip.vehicleId,
            excludedAssignmentId: trip.assignmentId,
          },
          connection,
        );

      if (activeVehicleAssignments === 0) {
        await driverTripModel.updateVehicleAssignment(
          {
            vehicleId: trip.vehicleId,
            availabilityStatus: 'available',
            assignedDriverId: null,
          },
          connection,
        );
      }
    }

    const tripLog = await driverTripModel.createTripLog(
      {
        shipmentId: trip.shipmentId,
        assignmentId: trip.assignmentId,
        driverId: driver.id,
        vehicleId: trip.vehicleId,
        status: transition.logStatus,
        title: transition.logTitle,
        description: buildProgressDescription(transition, payload),
        locationText: payload.locationText,
        latitude: payload.latitude,
        longitude: payload.longitude,
      },
      connection,
    );

    const updatedTrip = await driverTripModel.findTripById(
      {
        driverId: driver.id,
        assignmentId,
      },
      connection,
    );

    await createAudit(
      {
        action: transition.auditAction,
        entityId: trip.assignmentId,
        actorUserId: userId,
        requestMeta,
        oldValues: {
          assignmentStatus: trip.assignmentStatus,
          shipmentStatus: trip.shipmentStatus,
        },
        newValues: {
          assignmentStatus: updatedTrip.assignmentStatus,
          shipmentStatus: updatedTrip.shipmentStatus,
          tripLog,
        },
      },
      connection,
    );

    if (PROGRESS_NOTIFICATION_CONFIG[transitionKey]) {
      const notificationConfig = PROGRESS_NOTIFICATION_CONFIG[transitionKey];

      await notificationService.notifyShipmentStatus(
        {
          ...buildNotificationContext(updatedTrip),
          notificationType: notificationConfig.notificationType,
          title: notificationConfig.title,
          message: notificationConfig.message(updatedTrip),
        },
        connection,
      );
    }
    await connection.commit();

    return {
      trip: formatTrip(updatedTrip),
      tripLog,
      message: transition.message,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const startTrip = (payload) => updateTripProgress({
  ...payload,
  transitionKey: 'start',
});

const markPickupCompleted = (payload) => updateTripProgress({
  ...payload,
  transitionKey: 'pickupCompleted',
});

const markInTransit = async (payload) => {
  const driver = await getActiveDriver(payload.userId);
  const trip = await driverTripModel.findTripById({
    driverId: driver.id,
    assignmentId: payload.assignmentId,
  });

  assertTrip(trip);

  if (trip.assignmentStatus === 'in_transit' && trip.shipmentStatus === 'in_transit') {
    return updateTripStatus({
      ...payload,
      payload: {
        ...(payload.payload || {}),
        status: (payload.payload || {}).status || 'in_transit',
      },
    });
  }

  return updateTripProgress({
    ...payload,
    transitionKey: 'inTransit',
  });
};

const markDeliveryCompleted = (payload) => updateTripProgress({
  ...payload,
  transitionKey: 'deliveryCompleted',
});

const completeTrip = (payload) => updateTripProgress({
  ...payload,
  transitionKey: 'complete',
});

const uploadPickupProof = (payload) => uploadProof({
  ...payload,
  proofType: 'pickup',
});

const uploadDeliveryProof = (payload) => uploadProof({
  ...payload,
  proofType: 'delivery',
});

module.exports = {
  acceptTrip,
  completeTrip,
  getTripDetails,
  listTripHistory,
  listAssignedTrips,
  markDeliveryCompleted,
  markInTransit,
  markPickupCompleted,
  rejectTrip,
  startTrip,
  updateTripStatus,
  uploadDeliveryProof,
  uploadPickupProof,
};
