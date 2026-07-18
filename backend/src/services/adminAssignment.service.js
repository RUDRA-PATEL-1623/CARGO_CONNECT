const { getPool } = require('../config/database');
const adminAssignmentModel = require('../models/adminAssignment.model');
const adminShipmentModel = require('../models/adminShipment.model');
const auditLogModel = require('../models/auditLog.model');
const notificationService = require('./notification.service');
const AppError = require('../utils/appError');

const REPLACEABLE_ASSIGNMENT_STATUSES = ['assigned', 'accepted'];
const REPLACEABLE_SHIPMENT_STATUSES = ['assigned', 'accepted'];

const getAuditMeta = ({ actorUserId, requestMeta }) => ({
  actorUserId,
  ipAddress: requestMeta?.ipAddress || null,
  userAgent: requestMeta?.userAgent || null,
});

const createAudit = async (
  { action, entityType, entityId, actorUserId, requestMeta, oldValues, newValues },
  connection,
) => {
  await auditLogModel.createAuditLog(
    {
      ...getAuditMeta({ actorUserId, requestMeta }),
      action,
      entityType,
      entityId,
      oldValues,
      newValues,
    },
    connection,
  );
};

const assertShipment = (shipment) => {
  if (!shipment) {
    throw new AppError('Shipment was not found', 404);
  }
};

const assertAssignment = (assignment) => {
  if (!assignment) {
    throw new AppError('Assignment was not found', 404);
  }
};

const releaseCancelledAssignments = async (
  { assignments, shipmentId },
  connection,
) => {
  for (const assignment of assignments) {
    const activeDriverAssignments =
      await adminShipmentModel.countActiveDriverAssignments(
        {
          driverId: assignment.driverId,
          excludedShipmentId: shipmentId,
        },
        connection,
      );

    if (activeDriverAssignments === 0) {
      await adminShipmentModel.updateDriverAvailability(
        assignment.driverId,
        'available',
        connection,
      );
    }

    const activeVehicleAssignments =
      await adminShipmentModel.countActiveVehicleAssignments(
        {
          vehicleId: assignment.vehicleId,
          excludedShipmentId: shipmentId,
        },
        connection,
      );

    if (activeVehicleAssignments === 0) {
      await adminShipmentModel.updateVehicleAssignment(
        {
          vehicleId: assignment.vehicleId,
          availabilityStatus: 'available',
          assignedDriverId: null,
        },
        connection,
      );
    }
  }
};

const buildConflictValidation = async (
  { shipmentId, driverId, vehicleId, replaceAssignmentId = null },
  connection = null,
) => {
  const [shipment, driver, vehicle] = await Promise.all([
    adminShipmentModel.findById(shipmentId, connection),
    adminAssignmentModel.findDriver(driverId, connection),
    adminAssignmentModel.findVehicle(vehicleId, connection),
  ]);
  const replaceAssignment = replaceAssignmentId
    ? await adminAssignmentModel.findById(replaceAssignmentId, connection)
    : null;
  const conflicts = [];

  if (!shipment) {
    conflicts.push({
      field: 'shipmentId',
      message: 'Shipment was not found',
    });
  }

  if (!driver) {
    conflicts.push({
      field: 'driverId',
      message: 'Driver was not found',
    });
  } else if (driver.driverStatus !== 'active') {
    conflicts.push({
      field: 'driverId',
      message: 'Driver must be active',
      value: driver.driverStatus,
    });
  } else if (!['available', 'busy'].includes(driver.availabilityStatus)) {
    conflicts.push({
      field: 'driverId',
      message: 'Driver is not available for assignment',
      value: driver.availabilityStatus,
    });
  }

  const vehicleAssignedToReplacedAssignment =
    replaceAssignment
    && shipment
    && Number(replaceAssignment.shipmentId) === Number(shipment.id)
    && Number(vehicle?.assignedDriverId) === Number(replaceAssignment.driverId);

  if (!vehicle) {
    conflicts.push({
      field: 'vehicleId',
      message: 'Vehicle was not found',
    });
  } else if (['maintenance', 'inactive'].includes(vehicle.availabilityStatus)) {
    conflicts.push({
      field: 'vehicleId',
      message: 'Vehicle is not available for assignment',
      value: vehicle.availabilityStatus,
    });
  } else if (
    vehicle.assignedDriverId
    && Number(vehicle.assignedDriverId) !== Number(driverId)
    && !vehicleAssignedToReplacedAssignment
  ) {
    conflicts.push({
      field: 'vehicleId',
      message: 'Vehicle is assigned to another driver',
      assignedDriverId: vehicle.assignedDriverId,
    });
  }

  if (shipment && driver) {
    const driverConflicts = await adminAssignmentModel.listDriverConflicts(
      {
        driverId,
        excludedShipmentId: shipment.id,
      },
      connection,
    );

    if (driverConflicts.length > 0) {
      conflicts.push({
        field: 'driverId',
        message: 'Driver already has an active assignment',
        conflicts: driverConflicts,
      });
    }
  }

  if (shipment && vehicle) {
    const vehicleConflicts = await adminAssignmentModel.listVehicleConflicts(
      {
        vehicleId,
        excludedShipmentId: shipment.id,
      },
      connection,
    );

    if (vehicleConflicts.length > 0) {
      conflicts.push({
        field: 'vehicleId',
        message: 'Vehicle already has an active assignment',
        conflicts: vehicleConflicts,
      });
    }
  }

  if (replaceAssignmentId) {
    if (!replaceAssignment) {
      conflicts.push({
        field: 'replaceAssignmentId',
        message: 'Assignment was not found',
      });
    } else if (shipment && Number(replaceAssignment.shipmentId) !== Number(shipment.id)) {
      conflicts.push({
        field: 'replaceAssignmentId',
        message: 'Assignment does not belong to the selected shipment',
      });
    }
  }

  return {
    canAssign: conflicts.length === 0,
    shipment,
    driver,
    vehicle,
    conflicts,
  };
};

const validateConflicts = async (payload) => {
  const result = await buildConflictValidation(payload);

  return {
    canAssign: result.canAssign,
    conflicts: result.conflicts,
    resources: {
      shipment: result.shipment,
      driver: result.driver,
      vehicle: result.vehicle,
    },
  };
};

const assignShipment = async ({
  shipmentId,
  driverId,
  vehicleId,
  actorUserId,
  requestMeta,
  notes,
}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const shipment = await adminShipmentModel.findById(shipmentId, connection);
    assertShipment(shipment);

    if (shipment.shipmentStatus !== 'approved') {
      throw new AppError('Only approved shipments can be assigned', 409);
    }

    const activeAssignments = await adminShipmentModel.listActiveAssignments(
      shipment.id,
      connection,
    );

    if (activeAssignments.length > 0) {
      throw new AppError(
        'Shipment already has an active assignment. Use replace assignment instead.',
        409,
        { activeAssignments },
      );
    }

    const validation = await buildConflictValidation(
      {
        shipmentId,
        driverId,
        vehicleId,
      },
      connection,
    );

    if (!validation.canAssign) {
      throw new AppError('Assignment conflict validation failed', 422, {
        conflicts: validation.conflicts,
      });
    }

    const assignment = await adminShipmentModel.createAssignment(
      {
        shipmentId,
        driverId,
        vehicleId,
        actorUserId,
      },
      connection,
    );
    const updatedShipment = await adminShipmentModel.setShipmentAssigned(
      shipmentId,
      connection,
    );

    await adminShipmentModel.updateDriverAvailability(driverId, 'busy', connection);
    await adminShipmentModel.updateVehicleAssignment(
      {
        vehicleId,
        availabilityStatus: 'assigned',
        assignedDriverId: driverId,
      },
      connection,
    );

    await createAudit(
      {
        action: 'assignment.created',
        entityType: 'assignment',
        entityId: assignment.id,
        actorUserId,
        requestMeta,
        oldValues: {
          shipmentStatus: shipment.shipmentStatus,
        },
        newValues: {
          shipmentStatus: updatedShipment.shipmentStatus,
          assignment,
          notes: notes || null,
        },
      },
      connection,
    );

    await notificationService.notifyDriverAssigned(
      {
        customerUserId: updatedShipment.customerUserId,
        driverUserId: assignment.driverUserId,
        shipment: updatedShipment,
        assignment,
      },
      connection,
    );
    await connection.commit();

    return {
      shipment: updatedShipment,
      assignment,
      validation: {
        canAssign: true,
        conflicts: [],
      },
      message: 'Shipment assigned successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const replaceAssignment = async ({
  assignmentId,
  driverId,
  vehicleId,
  actorUserId,
  requestMeta,
  notes,
}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const existingAssignment = await adminAssignmentModel.findById(
      assignmentId,
      connection,
    );
    assertAssignment(existingAssignment);

    if (!REPLACEABLE_ASSIGNMENT_STATUSES.includes(existingAssignment.assignmentStatus)) {
      throw new AppError('Only assigned or accepted assignments can be replaced', 409);
    }

    const shipment = await adminShipmentModel.findById(
      existingAssignment.shipmentId,
      connection,
    );
    assertShipment(shipment);

    if (!REPLACEABLE_SHIPMENT_STATUSES.includes(shipment.shipmentStatus)) {
      throw new AppError(
        'Assignment can only be replaced before pickup starts',
        409,
      );
    }

    const validation = await buildConflictValidation(
      {
        shipmentId: shipment.id,
        driverId,
        vehicleId,
        replaceAssignmentId: assignmentId,
      },
      connection,
    );

    if (!validation.canAssign) {
      throw new AppError('Assignment conflict validation failed', 422, {
        conflicts: validation.conflicts,
      });
    }

    const activeAssignments = await adminShipmentModel.listActiveAssignments(
      shipment.id,
      connection,
    );
    await adminShipmentModel.cancelAssignments(
      {
        shipmentId: shipment.id,
        reason: notes || 'Assignment replaced by admin',
      },
      connection,
    );
    await releaseCancelledAssignments(
      {
        assignments: activeAssignments,
        shipmentId: shipment.id,
      },
      connection,
    );

    const assignment = await adminShipmentModel.createAssignment(
      {
        shipmentId: shipment.id,
        driverId,
        vehicleId,
        actorUserId,
      },
      connection,
    );
    const updatedShipment = await adminShipmentModel.setShipmentAssigned(
      shipment.id,
      connection,
    );

    await adminShipmentModel.updateDriverAvailability(driverId, 'busy', connection);
    await adminShipmentModel.updateVehicleAssignment(
      {
        vehicleId,
        availabilityStatus: 'assigned',
        assignedDriverId: driverId,
      },
      connection,
    );

    await createAudit(
      {
        action: 'assignment.replaced',
        entityType: 'assignment',
        entityId: assignment.id,
        actorUserId,
        requestMeta,
        oldValues: {
          replacedAssignment: existingAssignment,
          activeAssignments,
        },
        newValues: {
          shipmentStatus: updatedShipment.shipmentStatus,
          assignment,
          notes: notes || null,
        },
      },
      connection,
    );

    await notificationService.notifyDriverAssigned(
      {
        customerUserId: updatedShipment.customerUserId,
        driverUserId: assignment.driverUserId,
        shipment: updatedShipment,
        assignment,
      },
      connection,
    );
    await connection.commit();

    return {
      shipment: updatedShipment,
      replacedAssignment: existingAssignment,
      assignment,
      validation: {
        canAssign: true,
        conflicts: [],
      },
      message: 'Assignment replaced successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  assignShipment,
  replaceAssignment,
  validateConflicts,
};
