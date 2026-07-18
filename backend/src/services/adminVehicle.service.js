const { getPool } = require('../config/database');
const adminVehicleModel = require('../models/adminVehicle.model');
const auditLogModel = require('../models/auditLog.model');
const AppError = require('../utils/appError');

const normalizePagination = ({ page = 1, limit = 10 } = {}) => {
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(50, Math.max(1, Number(limit) || 10));

  return {
    page: safePage,
    limit: safeLimit,
    offset: (safePage - 1) * safeLimit,
  };
};

const normalizeIdentifier = (value) => {
  return value
    ? String(value).trim().toUpperCase().replace(/\s+/g, '')
    : null;
};

const buildVehicleNumber = (registrationNumber) => {
  const clean = registrationNumber.replace(/[^A-Z0-9]/g, '').slice(-32);
  return `CC-${clean}`;
};

const assertVehicle = (vehicle) => {
  if (!vehicle) {
    throw new AppError('Vehicle was not found', 404);
  }
};

const writeAuditLog = async (
  { actorUserId, action, entityId, oldValues = null, newValues = null, requestMeta = {} },
  connection,
) => {
  if (!actorUserId) {
    return;
  }

  await auditLogModel.createAuditLog(
    {
      actorUserId,
      action,
      entityType: 'vehicle',
      entityId,
      oldValues,
      newValues,
      ...requestMeta,
    },
    connection,
  );
};

const normalizeVehiclePayload = (payload) => {
  const registrationNumber =
    payload.registrationNumber === undefined
      ? undefined
      : normalizeIdentifier(payload.registrationNumber);
  const vehicleNumber =
    payload.vehicleNumber === undefined
      ? undefined
      : normalizeIdentifier(payload.vehicleNumber);
  const capacityValue = payload.capacityKg ?? payload.capacity;
  const assignedDriverId = payload.assignedDriverId;

  return {
    vehicleNumber,
    registrationNumber,
    vehicleType: payload.vehicleType || payload.type,
    model: payload.model,
    capacityKg:
      capacityValue === undefined || capacityValue === null
        ? undefined
        : Number(capacityValue),
    fuelType: payload.fuelType,
    insuranceExpiryDate: payload.insuranceExpiryDate || payload.insuranceExpiry,
    serviceDueDate: payload.serviceDueDate || payload.serviceDue,
    availabilityStatus: payload.availabilityStatus || payload.availability,
    assignedDriverId:
      assignedDriverId === undefined ? undefined : assignedDriverId || null,
    notes: payload.notes,
  };
};

const assertUniqueVehicleIdentifiers = async (
  { vehicleNumber, registrationNumber, currentVehicleId = null },
  connection,
) => {
  if (vehicleNumber) {
    const existing = await adminVehicleModel.findByVehicleNumber(
      vehicleNumber,
      connection,
    );

    if (existing && Number(existing.id) !== Number(currentVehicleId)) {
      throw new AppError('Vehicle number is already registered', 409);
    }
  }

  if (registrationNumber) {
    const existing = await adminVehicleModel.findByRegistrationNumber(
      registrationNumber,
      connection,
    );

    if (existing && Number(existing.id) !== Number(currentVehicleId)) {
      throw new AppError('Registration number is already registered', 409);
    }
  }
};

const assertAssignableDriver = async (assignedDriverId, connection) => {
  if (assignedDriverId === undefined || assignedDriverId === null) {
    return;
  }

  const driver = await adminVehicleModel.findAssignableDriver(
    assignedDriverId,
    connection,
  );

  if (!driver) {
    throw new AppError('Assigned driver must be an active driver', 422);
  }
};

const listVehicles = async (filters = {}) => {
  const pagination = normalizePagination(filters);
  const { rows, total } = await adminVehicleModel.listVehicles({
    filters,
    pagination,
  });

  return {
    vehicles: rows,
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
            title: 'No vehicles found',
            message: 'Try changing search, type, fuel, service, or availability filters.',
          }
        : null,
  };
};

const getVehicleDetails = async (vehicleId) => {
  const vehicle = await adminVehicleModel.findById(vehicleId);
  assertVehicle(vehicle);

  const recentAssignments = await adminVehicleModel.listRecentAssignments({
    vehicleId: vehicle.id,
    limit: 5,
  });

  return {
    vehicle,
    recentAssignments,
  };
};

const createVehicle = async (payload, context = {}) => {
  const pool = getPool();
  const connection = await pool.getConnection();
  const normalized = normalizeVehiclePayload(payload);
  const vehicleNumber =
    normalized.vehicleNumber || buildVehicleNumber(normalized.registrationNumber);
  const availabilityStatus =
    normalized.availabilityStatus ||
    (normalized.assignedDriverId ? 'assigned' : 'available');

  try {
    await connection.beginTransaction();
    await assertUniqueVehicleIdentifiers(
      {
        vehicleNumber,
        registrationNumber: normalized.registrationNumber,
      },
      connection,
    );
    await assertAssignableDriver(normalized.assignedDriverId, connection);

    const vehicle = await adminVehicleModel.createVehicle(
      {
        ...normalized,
        vehicleNumber,
        availabilityStatus,
      },
      connection,
    );

    await writeAuditLog(
      {
        actorUserId: context.actorUserId,
        action: 'vehicle.created',
        entityId: vehicle.id,
        newValues: vehicle,
        requestMeta: context.requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      vehicle,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const updateVehicle = async (vehicleId, payload, context = {}) => {
  const pool = getPool();
  const connection = await pool.getConnection();
  const normalized = normalizeVehiclePayload(payload);

  try {
    await connection.beginTransaction();

    const existingVehicle = await adminVehicleModel.findById(vehicleId, connection);
    assertVehicle(existingVehicle);

    await assertUniqueVehicleIdentifiers(
      {
        vehicleNumber: normalized.vehicleNumber,
        registrationNumber: normalized.registrationNumber,
        currentVehicleId: existingVehicle.id,
      },
      connection,
    );
    await assertAssignableDriver(normalized.assignedDriverId, connection);

    const vehicle = await adminVehicleModel.updateVehicleFields(
      {
        vehicleId,
        payload: normalized,
      },
      connection,
    );

    await writeAuditLog(
      {
        actorUserId: context.actorUserId,
        action: 'vehicle.updated',
        entityId: vehicle.id,
        oldValues: existingVehicle,
        newValues: vehicle,
        requestMeta: context.requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      vehicle,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const activateVehicle = async (vehicleId, context = {}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const existingVehicle = await adminVehicleModel.findById(vehicleId, connection);
    assertVehicle(existingVehicle);

    const vehicle = await adminVehicleModel.updateAvailability(
      {
        vehicleId,
        availabilityStatus: existingVehicle.assignedDriverId
          ? 'assigned'
          : 'available',
        assignedDriverId: existingVehicle.assignedDriverId || null,
      },
      connection,
    );

    await writeAuditLog(
      {
        actorUserId: context.actorUserId,
        action: 'vehicle.activated',
        entityId: vehicle.id,
        oldValues: existingVehicle,
        newValues: vehicle,
        requestMeta: context.requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      vehicle,
      status: 'available',
      message: 'Vehicle activated successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const deactivateVehicle = async (vehicleId, context = {}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const existingVehicle = await adminVehicleModel.findById(vehicleId, connection);
    assertVehicle(existingVehicle);

    const vehicle = await adminVehicleModel.updateAvailability(
      {
        vehicleId,
        availabilityStatus: 'inactive',
        assignedDriverId: null,
      },
      connection,
    );

    await writeAuditLog(
      {
        actorUserId: context.actorUserId,
        action: 'vehicle.deactivated',
        entityId: vehicle.id,
        oldValues: existingVehicle,
        newValues: vehicle,
        requestMeta: context.requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      vehicle,
      status: 'inactive',
      message: 'Vehicle deactivated successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  activateVehicle,
  createVehicle,
  deactivateVehicle,
  getVehicleDetails,
  listVehicles,
  updateVehicle,
};
