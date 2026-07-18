const customerModel = require('../models/customer.model');
const invoiceModel = require('../models/invoice.model');
const customerShipmentReadModel = require('../models/customerShipmentRead.model');
const AppError = require('../utils/appError');

const STATUS_FLOW = [
  { status: 'pending', label: 'Pending' },
  { status: 'approved', label: 'Approved' },
  { status: 'assigned', label: 'Assigned' },
  { status: 'accepted', label: 'Accepted' },
  { status: 'pickup_completed', label: 'Pickup Completed' },
  { status: 'in_transit', label: 'In Transit' },
  { status: 'delivered', label: 'Delivered' },
  { status: 'completed', label: 'Completed' },
];

const normalizePagination = ({ page = 1, limit = 10 } = {}) => {
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(50, Math.max(1, Number(limit) || 10));

  return {
    page: safePage,
    limit: safeLimit,
    offset: (safePage - 1) * safeLimit,
  };
};

const getActiveCustomer = async (userId) => {
  const customer = await customerModel.findByUserId(userId);

  if (!customer || customer.accountStatus !== 'active') {
    throw new AppError('Active customer profile is required', 403);
  }

  return customer;
};

const assertShipment = (shipment) => {
  if (!shipment) {
    throw new AppError('Shipment was not found', 404);
  }
};

const maskPhone = (phone) => {
  if (!phone) {
    return null;
  }

  const visible = phone.slice(-4);
  return `${'*'.repeat(Math.max(0, phone.length - 4))}${visible}`;
};

const withInvoiceLinks = (invoice) => {
  if (!invoice) {
    return null;
  }

  return {
    ...invoice,
    downloadUrl: `/api/v1/customer/invoices/${invoice.id}/download`,
  };
};

const formatAssignment = (assignment) => {
  if (!assignment) {
    return null;
  }

  return {
    id: assignment.id,
    assignmentCode: assignment.assignmentCode,
    assignmentStatus: assignment.assignmentStatus,
    assignedAt: assignment.assignedAt,
    acceptedAt: assignment.acceptedAt,
    startedAt: assignment.startedAt,
    completedAt: assignment.completedAt,
    driver: assignment.driverId
      ? {
          id: assignment.driverId,
          driverCode: assignment.driverCode,
          name: assignment.driverName,
          phoneMasked: maskPhone(assignment.driverPhone),
          rating: assignment.driverRating,
          completedTrips: assignment.driverCompletedTrips,
        }
      : null,
    vehicle: assignment.vehicleId
      ? {
          id: assignment.vehicleId,
          vehicleNumber: assignment.vehicleNumber,
          registrationNumber: assignment.vehicleRegistrationNumber,
          vehicleType: assignment.vehicleType,
          model: assignment.vehicleModel,
          capacityKg: assignment.vehicleCapacityKg,
        }
      : null,
  };
};

const addMinutes = (dateValue, minutes) => {
  if (!dateValue || minutes === null || minutes === undefined) {
    return null;
  }

  const date = new Date(dateValue);

  if (Number.isNaN(date.getTime())) {
    return null;
  }

  return new Date(date.getTime() + Number(minutes) * 60 * 1000).toISOString();
};

const eventTimeByStatus = ({ shipment, assignment, tripLogs }) => {
  const timestamps = new Map();

  if (shipment.createdAt) {
    timestamps.set('pending', shipment.createdAt);
  }

  if (shipment.approvedAt) {
    timestamps.set('approved', shipment.approvedAt);
  }

  if (assignment?.assignedAt) {
    timestamps.set('assigned', assignment.assignedAt);
  }

  if (assignment?.acceptedAt) {
    timestamps.set('accepted', assignment.acceptedAt);
  }

  if (shipment.completedAt) {
    timestamps.set('completed', shipment.completedAt);
  }

  tripLogs.forEach((log) => {
    if (!timestamps.has(log.status)) {
      timestamps.set(log.status, log.eventTime);
    }
  });

  return timestamps;
};

const buildTimeline = ({ shipment, assignment, tripLogs }) => {
  const currentIndex = STATUS_FLOW.findIndex(
    (step) => step.status === shipment.shipmentStatus,
  );
  const timestamps = eventTimeByStatus({ shipment, assignment, tripLogs });

  const steps = STATUS_FLOW.map((step, index) => {
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

  if (['cancelled', 'rejected'].includes(shipment.shipmentStatus)) {
    steps.push({
      status: shipment.shipmentStatus,
      label: shipment.shipmentStatus === 'cancelled' ? 'Cancelled' : 'Rejected',
      state: 'current',
      timestamp: shipment.cancelledAt || shipment.updatedAt,
      description: shipment.cancellationReason || null,
    });
  }

  return {
    currentStatus: shipment.shipmentStatus,
    steps,
    events: tripLogs,
  };
};

const getShipmentContext = async (userId, shipmentId) => {
  const customer = await getActiveCustomer(userId);
  const shipment = await customerShipmentReadModel.findShipmentDetail({
    customerId: customer.id,
    shipmentId,
  });

  assertShipment(shipment);

  return {
    customer,
    shipment,
  };
};

const listHistory = async (userId, filters = {}) => {
  const customer = await getActiveCustomer(userId);
  const pagination = normalizePagination(filters);
  const { rows, total } = await customerShipmentReadModel.listShipments({
    customerId: customer.id,
    filters,
    pagination,
  });

  return {
    shipments: rows,
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
            title: 'No shipments found',
            message: 'Try changing search, status, date, or category filters.',
          }
        : null,
  };
};

const getDetails = async (userId, shipmentId) => {
  const { customer, shipment } = await getShipmentContext(userId, shipmentId);
  const [payment, invoice, assignment, proofs, tripLogs] = await Promise.all([
    customerShipmentReadModel.findLatestPayment({
      customerId: customer.id,
      shipmentId: shipment.id,
    }),
    invoiceModel.findByShipmentIdForCustomer({
      shipmentId: shipment.id,
      customerId: customer.id,
    }),
    customerShipmentReadModel.findLatestAssignment(shipment.id),
    customerShipmentReadModel.listProofs({ shipmentId: shipment.id }),
    customerShipmentReadModel.listTripLogs(shipment.id),
  ]);
  const timeline = buildTimeline({ shipment, assignment, tripLogs });

  return {
    shipment,
    payment,
    invoice: withInvoiceLinks(invoice),
    assignment: formatAssignment(assignment),
    proofs,
    timelinePreview: timeline.steps.slice(0, 4),
    supportAction: {
      enabled: true,
      endpointHint: `/api/v1/customer/support`,
    },
  };
};

const getTimeline = async (userId, shipmentId) => {
  const { shipment } = await getShipmentContext(userId, shipmentId);
  const [assignment, tripLogs] = await Promise.all([
    customerShipmentReadModel.findLatestAssignment(shipment.id),
    customerShipmentReadModel.listTripLogs(shipment.id),
  ]);

  return buildTimeline({ shipment, assignment, tripLogs });
};

const getTracking = async (userId, shipmentId) => {
  const { shipment } = await getShipmentContext(userId, shipmentId);
  const [assignment, tripLogs] = await Promise.all([
    customerShipmentReadModel.findLatestAssignment(shipment.id),
    customerShipmentReadModel.listTripLogs(shipment.id),
  ]);
  const latestLog = tripLogs[tripLogs.length - 1] || null;
  const timeline = buildTimeline({ shipment, assignment, tripLogs });

  return {
    currentStatus: {
      status: shipment.shipmentStatus,
      label:
        STATUS_FLOW.find((step) => step.status === shipment.shipmentStatus)
          ?.label || shipment.shipmentStatus,
      updatedAt: latestLog?.eventTime || shipment.updatedAt,
      locationText: latestLog?.locationText || null,
    },
    map: {
      provider: 'placeholder',
      pickup: {
        address: shipment.pickupAddress,
        latitude: shipment.pickupLatitude,
        longitude: shipment.pickupLongitude,
      },
      delivery: {
        address: shipment.deliveryAddress,
        latitude: shipment.deliveryLatitude,
        longitude: shipment.deliveryLongitude,
      },
      currentLocation: latestLog
        ? {
            locationText: latestLog.locationText,
            latitude: latestLog.latitude,
            longitude: latestLog.longitude,
            eventTime: latestLog.eventTime,
          }
        : null,
    },
    assignment: formatAssignment(assignment),
    eta: {
      scheduledPickupAt: shipment.pickupDateTime,
      estimatedDurationMinutes: shipment.estimatedDurationMinutes,
      estimatedDeliveryAt: addMinutes(
        shipment.pickupDateTime,
        shipment.estimatedDurationMinutes,
      ),
    },
    routeSummary: {
      estimatedDistanceKm: shipment.estimatedDistanceKm,
      pickupAddress: shipment.pickupAddress,
      deliveryAddress: shipment.deliveryAddress,
    },
    actions: {
      callDriver: {
        enabled: false,
        reason: 'Driver calling is a mock placeholder until telephony is integrated.',
      },
      support: {
        enabled: true,
        endpointHint: '/api/v1/customer/support',
      },
    },
    timelinePreview: timeline.steps.slice(0, 5),
  };
};

const listProofs = async (userId, shipmentId, filters = {}) => {
  const { shipment } = await getShipmentContext(userId, shipmentId);
  const proofs = await customerShipmentReadModel.listProofs({
    shipmentId: shipment.id,
    proofType: filters.proofType,
  });

  return {
    shipment: {
      id: shipment.id,
      shipmentCode: shipment.shipmentCode,
    },
    proofs,
    emptyState:
      proofs.length === 0
        ? {
            title: 'No proofs uploaded yet',
            message: 'Pickup and delivery proofs will appear after driver upload.',
          }
        : null,
  };
};

const getProof = async (userId, shipmentId, proofId) => {
  const { shipment } = await getShipmentContext(userId, shipmentId);
  const proof = await customerShipmentReadModel.findProofById({
    shipmentId: shipment.id,
    proofId,
  });

  if (!proof) {
    throw new AppError('Proof was not found', 404);
  }

  return {
    shipment: {
      id: shipment.id,
      shipmentCode: shipment.shipmentCode,
    },
    proof,
    actions: {
      download: {
        enabled: true,
        url: proof.fileUrl,
      },
      viewFullScreen: {
        enabled: true,
        url: proof.fileUrl,
      },
    },
  };
};

module.exports = {
  getDetails,
  getProof,
  getTimeline,
  getTracking,
  listHistory,
  listProofs,
};
