const { getPool } = require('../config/database');
const { USER_ROLES } = require('../constants/auth.constants');
const auditLogModel = require('../models/auditLog.model');
const driverModel = require('../models/driver.model');
const driverTripModel = require('../models/driverTrip.model');
const userModel = require('../models/user.model');
const AppError = require('../utils/appError');
const { sanitizeUser } = require('../utils/auth');

const getActiveDriverProfile = async (userId, connection = null) => {
  const user = await userModel.findById(userId, { connection });
  const driver = await driverModel.findByUserId(userId, connection);

  if (!user || user.role !== USER_ROLES.DRIVER) {
    throw new AppError('Driver account was not found', 404);
  }

  if (!driver || driver.driverStatus !== 'active') {
    throw new AppError('Driver profile is not active', 403);
  }

  return {
    user,
    driver,
  };
};

const getProfile = async (userId) => {
  const { user, driver } = await getActiveDriverProfile(userId);
  const activeAssignments = await driverTripModel.countActiveDriverAssignments({
    driverId: driver.id,
  });

  return {
    user: sanitizeUser(user),
    profile: {
      type: 'driver',
      ...driver,
      activeAssignments,
    },
  };
};

const updateAvailability = async ({ userId, availabilityStatus, requestMeta }) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const { driver } = await getActiveDriverProfile(userId, connection);
    const activeAssignments = await driverTripModel.countActiveDriverAssignments(
      {
        driverId: driver.id,
      },
      connection,
    );

    if (activeAssignments > 0) {
      throw new AppError(
        'Availability cannot be changed while the driver has an active assignment',
        409,
        {
          activeAssignments,
          currentAvailabilityStatus: driver.availabilityStatus,
        },
      );
    }

    await driverTripModel.updateDriverAvailability(
      {
        driverId: driver.id,
        availabilityStatus,
      },
      connection,
    );

    const updatedDriver = await driverModel.findByUserId(userId, connection);

    await auditLogModel.createAuditLog(
      {
        actorUserId: userId,
        action: 'driver.availability.updated',
        entityType: 'driver',
        entityId: driver.id,
        oldValues: {
          availabilityStatus: driver.availabilityStatus,
        },
        newValues: {
          availabilityStatus: updatedDriver.availabilityStatus,
        },
        ipAddress: requestMeta?.ipAddress || null,
        userAgent: requestMeta?.userAgent || null,
      },
      connection,
    );

    await connection.commit();

    return {
      profile: {
        type: 'driver',
        ...updatedDriver,
        activeAssignments,
      },
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const logout = async ({ userId, requestMeta }) => {
  const { driver } = await getActiveDriverProfile(userId);

  await auditLogModel.createAuditLog({
    actorUserId: userId,
    action: 'driver.logout',
    entityType: 'driver',
    entityId: driver.id,
    oldValues: null,
    newValues: {
      tokenRevoked: false,
      reason: 'Stateless JWT logout acknowledged; client should discard token.',
    },
    ipAddress: requestMeta?.ipAddress || null,
    userAgent: requestMeta?.userAgent || null,
  });

  return {
    loggedOut: true,
    tokenRevoked: false,
    message: 'Logout acknowledged. Discard the JWT on the client.',
  };
};

module.exports = {
  getProfile,
  logout,
  updateAvailability,
};
