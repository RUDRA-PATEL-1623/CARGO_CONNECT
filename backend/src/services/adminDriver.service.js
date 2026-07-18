const crypto = require('crypto');

const { getPool } = require('../config/database');
const { USER_ROLES, USER_STATUSES } = require('../constants/auth.constants');
const adminDriverModel = require('../models/adminDriver.model');
const auditLogModel = require('../models/auditLog.model');
const userModel = require('../models/user.model');
const AppError = require('../utils/appError');
const {
  createPublicId,
  hashPassword,
  normalizeEmail,
  normalizePhone,
  sanitizeUser,
} = require('../utils/auth');

const normalizePagination = ({ page = 1, limit = 10 } = {}) => {
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(50, Math.max(1, Number(limit) || 10));

  return {
    page: safePage,
    limit: safeLimit,
    offset: (safePage - 1) * safeLimit,
  };
};

const generateDriverCode = (userId) => {
  return `DRV-${String(userId).padStart(4, '0')}`;
};

const generateTemporaryPassword = () => {
  return `CCDrv-${crypto.randomBytes(4).toString('hex')}!1`;
};

const mapDriverStatusToUserStatus = (driverStatus) => {
  return driverStatus === 'active'
    ? USER_STATUSES.ACTIVE
    : USER_STATUSES.INACTIVE;
};

const assertDriver = (driver) => {
  if (!driver) {
    throw new AppError('Driver was not found', 404);
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
      entityType: 'driver',
      entityId,
      oldValues,
      newValues,
      ...requestMeta,
    },
    connection,
  );
};

const assertUniqueIdentity = async (
  { email, phone, username, currentUserId = null },
  connection,
) => {
  const checks = [
    ['Email', email, (value) => userModel.findByEmail(value, { connection })],
    ['Phone', phone, (value) => userModel.findByPhone(value, { connection })],
    ['Username', username, (value) => userModel.findByUsername(value, { connection })],
  ];

  for (const [label, value, finder] of checks) {
    if (!value) {
      continue;
    }

    const existing = await finder(value);

    if (existing && Number(existing.id) !== Number(currentUserId)) {
      throw new AppError(`${label} is already registered`, 409);
    }
  }
};

const assertUniqueLicense = async (
  { licenseNumber, currentDriverId = null },
  connection,
) => {
  if (!licenseNumber) {
    return;
  }

  const existing = await adminDriverModel.findByLicenseNumber(
    licenseNumber,
    connection,
  );

  if (existing && Number(existing.id) !== Number(currentDriverId)) {
    throw new AppError('License number is already assigned to another driver', 409);
  }
};

const normalizeDriverPayload = (payload) => {
  const driverStatus = payload.driverStatus || payload.activeStatus;

  return {
    name: payload.name ? String(payload.name).trim() : undefined,
    username: payload.username ? String(payload.username).trim() : undefined,
    email: payload.email === undefined ? undefined : normalizeEmail(payload.email),
    phone: payload.phone === undefined ? undefined : normalizePhone(payload.phone),
    licenseNumber:
      payload.licenseNumber === undefined
        ? undefined
        : String(payload.licenseNumber).trim().toUpperCase(),
    licenseExpiryDate: payload.licenseExpiryDate,
    addressLine1: payload.addressLine1 || payload.address || undefined,
    addressLine2: payload.addressLine2,
    city: payload.city,
    state: payload.state,
    postalCode: payload.postalCode,
    availabilityStatus: payload.availabilityStatus,
    driverStatus,
    emergencyContactName: payload.emergencyContactName,
    emergencyContactPhone: payload.emergencyContactPhone,
  };
};

const listDrivers = async (filters = {}) => {
  const pagination = normalizePagination(filters);
  const { rows, total } = await adminDriverModel.listDrivers({
    filters,
    pagination,
  });

  return {
    drivers: rows,
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
            title: 'No drivers found',
            message: 'Try changing search, status, availability, or license filters.',
          }
        : null,
  };
};

const getDriverDetails = async (driverId) => {
  const driver = await adminDriverModel.findById(driverId);
  assertDriver(driver);

  const recentAssignments = await adminDriverModel.listRecentAssignments({
    driverId: driver.id,
    limit: 5,
  });

  return {
    driver,
    recentAssignments,
  };
};

const createDriver = async (payload, context = {}) => {
  const pool = getPool();
  const connection = await pool.getConnection();
  const normalized = normalizeDriverPayload(payload);
  const temporaryPassword = payload.password || generateTemporaryPassword();
  const generatedPassword = !payload.password;
  const driverStatus = normalized.driverStatus || 'active';

  try {
    await connection.beginTransaction();
    await assertUniqueIdentity(
      {
        email: normalized.email,
        phone: normalized.phone,
        username: normalized.username,
      },
      connection,
    );
    await assertUniqueLicense(
      {
        licenseNumber: normalized.licenseNumber,
      },
      connection,
    );

    const user = await userModel.createUser(
      {
        publicId: createPublicId(),
        role: USER_ROLES.DRIVER,
        name: normalized.name,
        username: normalized.username,
        email: normalized.email,
        phone: normalized.phone,
        passwordHash: await hashPassword(temporaryPassword),
        status: mapDriverStatusToUserStatus(driverStatus),
      },
      connection,
    );
    const driver = await adminDriverModel.createDriver(
      {
        userId: user.id,
        driverCode: generateDriverCode(user.id),
        licenseNumber: normalized.licenseNumber,
        licenseExpiryDate: normalized.licenseExpiryDate,
        addressLine1: normalized.addressLine1,
        addressLine2: normalized.addressLine2,
        city: normalized.city,
        state: normalized.state,
        postalCode: normalized.postalCode,
        availabilityStatus: normalized.availabilityStatus || 'available',
        driverStatus,
        emergencyContactName: normalized.emergencyContactName,
        emergencyContactPhone: normalized.emergencyContactPhone,
      },
      connection,
    );

    await writeAuditLog(
      {
        actorUserId: context.actorUserId,
        action: 'driver.created',
        entityId: driver.id,
        newValues: driver,
        requestMeta: context.requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      driver,
      loginCredentials: {
        username: user.username,
        email: user.email,
        temporaryPassword: generatedPassword ? temporaryPassword : undefined,
        generatedPassword,
      },
      user: sanitizeUser(user),
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const updateDriver = async (driverId, payload, context = {}) => {
  const pool = getPool();
  const connection = await pool.getConnection();
  const normalized = normalizeDriverPayload(payload);

  try {
    await connection.beginTransaction();

    const existingDriver = await adminDriverModel.findById(driverId, connection);
    assertDriver(existingDriver);

    await assertUniqueIdentity(
      {
        email: normalized.email,
        phone: normalized.phone,
        username: normalized.username,
        currentUserId: existingDriver.userId,
      },
      connection,
    );
    await assertUniqueLicense(
      {
        licenseNumber: normalized.licenseNumber,
        currentDriverId: existingDriver.id,
      },
      connection,
    );

    const userPayload = {
      name: normalized.name,
      username: normalized.username,
      email: normalized.email,
      phone: normalized.phone,
    };

    if (payload.password) {
      userPayload.passwordHash = await hashPassword(payload.password);
    }

    if (normalized.driverStatus !== undefined) {
      userPayload.userStatus = mapDriverStatusToUserStatus(
        normalized.driverStatus,
      );
    }

    await adminDriverModel.updateUserFields(
      {
        userId: existingDriver.userId,
        payload: userPayload,
      },
      connection,
    );
    const driver = await adminDriverModel.updateDriverFields(
      {
        driverId,
        payload: normalized,
      },
      connection,
    );

    await writeAuditLog(
      {
        actorUserId: context.actorUserId,
        action: 'driver.updated',
        entityId: driver.id,
        oldValues: existingDriver,
        newValues: driver,
        requestMeta: context.requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      driver,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const activateDriver = async (driverId, context = {}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const existingDriver = await adminDriverModel.findById(driverId, connection);
    assertDriver(existingDriver);

    const driver = await adminDriverModel.updateStatus(
      {
        driverId,
        driverStatus: 'active',
        availabilityStatus:
          existingDriver.availabilityStatus === 'busy' ? 'busy' : 'available',
        userStatus: USER_STATUSES.ACTIVE,
      },
      connection,
    );

    await writeAuditLog(
      {
        actorUserId: context.actorUserId,
        action: 'driver.activated',
        entityId: driver.id,
        oldValues: existingDriver,
        newValues: driver,
        requestMeta: context.requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      driver,
      status: 'active',
      message: 'Driver account activated successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const deactivateDriver = async (driverId, context = {}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const existingDriver = await adminDriverModel.findById(driverId, connection);
    assertDriver(existingDriver);

    const driver = await adminDriverModel.updateStatus(
      {
        driverId,
        driverStatus: 'inactive',
        availabilityStatus: 'offline',
        userStatus: USER_STATUSES.INACTIVE,
      },
      connection,
    );

    await writeAuditLog(
      {
        actorUserId: context.actorUserId,
        action: 'driver.deactivated',
        entityId: driver.id,
        oldValues: existingDriver,
        newValues: driver,
        requestMeta: context.requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      driver,
      status: 'inactive',
      message: 'Driver account deactivated successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  activateDriver,
  createDriver,
  deactivateDriver,
  getDriverDetails,
  listDrivers,
  updateDriver,
};
