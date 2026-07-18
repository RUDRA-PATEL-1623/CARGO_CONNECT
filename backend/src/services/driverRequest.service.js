const { getPool } = require('../config/database');
const driverModel = require('../models/driver.model');
const driverRequestModel = require('../models/driverRequest.model');
const auditLogModel = require('../models/auditLog.model');
const notificationService = require('./notification.service');
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

const getActiveDriver = async (userId, connection = null) => {
  const driver = await driverModel.findByUserId(userId, connection);

  if (!driver || driver.driverStatus !== 'active') {
    throw new AppError('Active driver profile is required', 403);
  }

  return driver;
};

const createAudit = async (
  { action, entityType, entityId, actorUserId, requestMeta, oldValues, newValues },
  connection,
) => {
  await auditLogModel.createAuditLog(
    {
      actorUserId,
      action,
      entityType,
      entityId,
      oldValues,
      newValues,
      ipAddress: requestMeta?.ipAddress || null,
      userAgent: requestMeta?.userAgent || null,
    },
    connection,
  );
};

const buildFileUrl = (folder, file) => `/uploads/${folder}/${file.filename}`;

const resolveDriverContext = async (
  { driverId, assignmentId, vehicleId },
  connection,
) => {
  let assignment = null;
  let vehicle = null;
  let resolvedVehicleId = vehicleId || null;
  let shipmentId = null;

  if (assignmentId) {
    assignment = await driverRequestModel.findDriverAssignment(
      {
        driverId,
        assignmentId,
      },
      connection,
    );

    if (!assignment) {
      throw new AppError('Assignment was not found for this driver', 404);
    }

    resolvedVehicleId = resolvedVehicleId || assignment.vehicleId;
    shipmentId = assignment.shipmentId;

    if (
      vehicleId
      && assignment.vehicleId
      && Number(vehicleId) !== Number(assignment.vehicleId)
    ) {
      throw new AppError('Vehicle does not belong to the selected assignment', 422, {
        assignmentVehicleId: assignment.vehicleId,
        vehicleId,
      });
    }
  }

  if (resolvedVehicleId) {
    vehicle = await driverRequestModel.findDriverVehicle(
      {
        driverId,
        vehicleId: resolvedVehicleId,
      },
      connection,
    );

    if (!vehicle) {
      throw new AppError('Vehicle was not found for this driver', 404);
    }
  }

  return {
    assignment,
    vehicle,
    vehicleId: resolvedVehicleId,
    shipmentId,
  };
};

const createReport = async ({
  userId,
  reportType,
  issueType,
  severity,
  description,
  assignmentId,
  vehicleId,
  attachmentFile,
  locationText,
  latitude,
  longitude,
  requestMeta,
}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const driver = await getActiveDriver(userId, connection);
    const context = await resolveDriverContext(
      {
        driverId: driver.id,
        assignmentId,
        vehicleId,
      },
      connection,
    );

    const report = await driverRequestModel.createReport(
      {
        driverId: driver.id,
        vehicleId: context.vehicleId,
        assignmentId: assignmentId || null,
        shipmentId: context.shipmentId,
        reportType,
        issueType,
        severity: severity || 'medium',
        description,
        attachmentUrl: attachmentFile
          ? buildFileUrl('reports', attachmentFile)
          : null,
        locationText,
        latitude,
        longitude,
      },
      connection,
    );

    await createAudit(
      {
        action: `driver.report.${reportType}.created`,
        entityType: 'emergency_report',
        entityId: report.id,
        actorUserId: userId,
        requestMeta,
        newValues: report,
      },
      connection,
    );

    await notificationService.notifyEmergencyReported(
      {
        report,
      },
      connection,
    );
    await connection.commit();

    return {
      report,
      message:
        reportType === 'breakdown'
          ? 'Breakdown report submitted successfully.'
          : 'Emergency report submitted successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const createEmergencyReport = (payload) => createReport(payload);

const createBreakdownReport = (payload) => createReport({
  ...payload,
  reportType: 'breakdown',
});

const listReports = async (userId, filters = {}) => {
  const driver = await getActiveDriver(userId);
  const pagination = normalizePagination(filters);
  const { rows, total } = await driverRequestModel.listDriverReports({
    driverId: driver.id,
    filters,
    pagination,
  });

  return {
    reports: rows,
    meta: {
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(total / pagination.limit),
      hasMore: pagination.page * pagination.limit < total,
    },
  };
};

const createFuelRequest = async ({
  userId,
  assignmentId,
  vehicleId,
  fuelAmountLiters,
  billAmount,
  fuelStation,
  notes,
  requestMeta,
}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const driver = await getActiveDriver(userId, connection);
    const context = await resolveDriverContext(
      {
        driverId: driver.id,
        assignmentId,
        vehicleId,
      },
      connection,
    );

    const fuelRequest = await driverRequestModel.createFuelRequest(
      {
        driverId: driver.id,
        vehicleId: context.vehicleId,
        assignmentId: assignmentId || null,
        fuelAmountLiters,
        billAmount,
        fuelStation,
        notes,
      },
      connection,
    );

    await createAudit(
      {
        action: 'driver.fuel_request.created',
        entityType: 'fuel_request',
        entityId: fuelRequest.id,
        actorUserId: userId,
        requestMeta,
        newValues: fuelRequest,
      },
      connection,
    );

    await connection.commit();

    return {
      fuelRequest,
      message: 'Fuel request submitted successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const listFuelRequests = async (userId, filters = {}) => {
  const driver = await getActiveDriver(userId);
  const pagination = normalizePagination(filters);
  const { rows, total } = await driverRequestModel.listDriverFuelRequests({
    driverId: driver.id,
    filters,
    pagination,
  });

  return {
    fuelRequests: rows,
    meta: {
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(total / pagination.limit),
      hasMore: pagination.page * pagination.limit < total,
    },
  };
};

const uploadFuelBill = async ({
  userId,
  fuelRequestId,
  billFile,
  notes,
  requestMeta,
}) => {
  if (!billFile) {
    throw new AppError('Fuel bill file is required in form field "bill"', 422);
  }

  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const driver = await getActiveDriver(userId, connection);
    const existing = await driverRequestModel.findFuelRequestById(
      fuelRequestId,
      connection,
    );

    if (!existing || Number(existing.driverId) !== Number(driver.id)) {
      throw new AppError('Fuel request was not found for this driver', 404);
    }

    if (existing.requestStatus !== 'pending') {
      throw new AppError('Fuel bill can only be uploaded while request is pending', 409, {
        requestStatus: existing.requestStatus,
      });
    }

    const fuelRequest = await driverRequestModel.updateFuelBill(
      {
        fuelRequestId,
        billFileUrl: buildFileUrl('fuel-bills', billFile),
        billFileName: billFile.originalname,
        billFileMimeType: billFile.mimetype,
        billFileSizeBytes: billFile.size,
        notes,
      },
      connection,
    );

    await createAudit(
      {
        action: 'driver.fuel_request.bill_uploaded',
        entityType: 'fuel_request',
        entityId: fuelRequest.id,
        actorUserId: userId,
        requestMeta,
        oldValues: {
          billFileUrl: existing.billFileUrl,
        },
        newValues: {
          billFileUrl: fuelRequest.billFileUrl,
          billFileName: fuelRequest.billFileName,
        },
      },
      connection,
    );

    await connection.commit();

    return {
      fuelRequest,
      message: 'Fuel bill uploaded successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  createBreakdownReport,
  createEmergencyReport,
  createFuelRequest,
  listFuelRequests,
  listReports,
  uploadFuelBill,
};
