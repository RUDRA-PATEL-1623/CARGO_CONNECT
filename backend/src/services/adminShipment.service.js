const { getPool } = require('../config/database');
const adminShipmentModel = require('../models/adminShipment.model');
const auditLogModel = require('../models/auditLog.model');
const notificationService = require('./notification.service');
const AppError = require('../utils/appError');

const TERMINAL_STATUSES = ['delivered', 'completed', 'cancelled', 'rejected'];
const REASSIGNABLE_STATUSES = ['approved', 'assigned', 'accepted'];

const normalizePagination = ({ page = 1, limit = 10 } = {}) => {
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(50, Math.max(1, Number(limit) || 10));

  return {
    page: safePage,
    limit: safeLimit,
    offset: (safePage - 1) * safeLimit,
  };
};

const assertShipment = (shipment) => {
  if (!shipment) {
    throw new AppError('Shipment was not found', 404);
  }
};

const buildAuditMeta = ({ actorUserId, requestMeta }) => ({
  actorUserId,
  ipAddress: requestMeta?.ipAddress || null,
  userAgent: requestMeta?.userAgent || null,
});

const writeShipmentAudit = async (
  { action, actorUserId, shipmentId, oldValues, newValues, requestMeta },
  connection,
) => {
  await auditLogModel.createAuditLog(
    {
      ...buildAuditMeta({ actorUserId, requestMeta }),
      action,
      entityType: 'shipment',
      entityId: shipmentId,
      oldValues,
      newValues,
    },
    connection,
  );
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

const listShipments = async (filters = {}) => {
  const pagination = normalizePagination(filters);
  const { rows, total } = await adminShipmentModel.listShipments({
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
            message: 'Try changing search, status, payment, date, or assignment filters.',
          }
        : null,
  };
};

const getShipmentDetails = async (shipmentId) => {
  const shipment = await adminShipmentModel.findById(shipmentId);
  assertShipment(shipment);

  const [
    payment,
    invoice,
    assignments,
    proofs,
    tripLogs,
  ] = await Promise.all([
    adminShipmentModel.findLatestPayment(shipment.id),
    adminShipmentModel.findLatestInvoice(shipment.id),
    adminShipmentModel.listAssignments(shipment.id),
    adminShipmentModel.listProofs(shipment.id),
    adminShipmentModel.listTripLogs(shipment.id),
  ]);

  return {
    shipment,
    payment,
    invoice,
    assignments,
    currentAssignment: assignments[0] || null,
    proofs,
    tripLogs,
  };
};

const approveShipment = async ({ shipmentId, actorUserId, requestMeta, notes }) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const shipment = await adminShipmentModel.findById(shipmentId, connection);
    assertShipment(shipment);

    if (shipment.shipmentStatus !== 'pending') {
      throw new AppError('Only pending shipments can be approved', 409);
    }

    if (shipment.paymentStatus !== 'paid') {
      throw new AppError('Shipment must be paid before approval', 422);
    }

    const updatedShipment = await adminShipmentModel.approveShipment(
      {
        shipmentId,
        actorUserId,
      },
      connection,
    );

    await writeShipmentAudit(
      {
        action: 'shipment.approved',
        actorUserId,
        shipmentId,
        oldValues: {
          shipmentStatus: shipment.shipmentStatus,
          paymentStatus: shipment.paymentStatus,
        },
        newValues: {
          shipmentStatus: updatedShipment.shipmentStatus,
          approvedByUserId: actorUserId,
          notes: notes || null,
        },
        requestMeta,
      },
      connection,
    );

    await notificationService.notifyShipmentApproved(
      {
        customerUserId: updatedShipment.customerUserId,
        shipment: updatedShipment,
      },
      connection,
    );
    await connection.commit();

    return {
      shipment: updatedShipment,
      message: 'Shipment approved successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const rejectShipment = async ({ shipmentId, actorUserId, requestMeta, reason }) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const shipment = await adminShipmentModel.findById(shipmentId, connection);
    assertShipment(shipment);

    if (shipment.shipmentStatus !== 'pending') {
      throw new AppError('Only pending shipments can be rejected', 409);
    }

    const activeAssignments = await adminShipmentModel.listActiveAssignments(
      shipmentId,
      connection,
    );
    await adminShipmentModel.cancelAssignments(
      {
        shipmentId,
        reason,
      },
      connection,
    );
    await releaseCancelledAssignments(
      {
        assignments: activeAssignments,
        shipmentId,
      },
      connection,
    );

    const updatedShipment = await adminShipmentModel.rejectShipment(
      {
        shipmentId,
        actorUserId,
        reason,
      },
      connection,
    );

    await writeShipmentAudit(
      {
        action: 'shipment.rejected',
        actorUserId,
        shipmentId,
        oldValues: {
          shipmentStatus: shipment.shipmentStatus,
        },
        newValues: {
          shipmentStatus: updatedShipment.shipmentStatus,
          reason,
        },
        requestMeta,
      },
      connection,
    );

    await notificationService.notifyShipmentCancelled(
      {
        customerUserId: updatedShipment.customerUserId,
        driverUserIds: activeAssignments.map((assignment) => assignment.driverUserId),
        shipment: updatedShipment,
        reason,
      },
      connection,
    );
    await connection.commit();

    return {
      shipment: updatedShipment,
      message: 'Shipment rejected successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const cancelShipment = async ({ shipmentId, actorUserId, requestMeta, reason }) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const shipment = await adminShipmentModel.findById(shipmentId, connection);
    assertShipment(shipment);

    if (TERMINAL_STATUSES.includes(shipment.shipmentStatus)) {
      throw new AppError('Terminal shipments cannot be cancelled', 409);
    }

    const activeAssignments = await adminShipmentModel.listActiveAssignments(
      shipmentId,
      connection,
    );
    await adminShipmentModel.cancelAssignments(
      {
        shipmentId,
        reason,
      },
      connection,
    );
    await releaseCancelledAssignments(
      {
        assignments: activeAssignments,
        shipmentId,
      },
      connection,
    );

    const updatedShipment = await adminShipmentModel.cancelShipment(
      {
        shipmentId,
        actorUserId,
        reason,
      },
      connection,
    );

    await writeShipmentAudit(
      {
        action: 'shipment.cancelled',
        actorUserId,
        shipmentId,
        oldValues: {
          shipmentStatus: shipment.shipmentStatus,
          activeAssignments,
        },
        newValues: {
          shipmentStatus: updatedShipment.shipmentStatus,
          reason,
        },
        requestMeta,
      },
      connection,
    );

    await notificationService.notifyShipmentCancelled(
      {
        customerUserId: updatedShipment.customerUserId,
        driverUserIds: activeAssignments.map((assignment) => assignment.driverUserId),
        shipment: updatedShipment,
        reason,
      },
      connection,
    );
    await connection.commit();

    return {
      shipment: updatedShipment,
      message: 'Shipment cancelled successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const reassignShipment = async ({
  shipmentId,
  actorUserId,
  requestMeta,
  driverId,
  vehicleId,
  notes,
}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const shipment = await adminShipmentModel.findById(shipmentId, connection);
    assertShipment(shipment);

    if (!REASSIGNABLE_STATUSES.includes(shipment.shipmentStatus)) {
      throw new AppError(
        'Shipment can only be assigned or reassigned after approval and before pickup starts',
        409,
      );
    }

    const driver = await adminShipmentModel.findAssignableDriver(
      {
        driverId,
        shipmentId,
      },
      connection,
    );

    if (!driver) {
      throw new AppError('Driver is not available for this shipment', 422);
    }

    const vehicle = await adminShipmentModel.findAssignableVehicle(
      {
        vehicleId,
        driverId,
        shipmentId,
      },
      connection,
    );

    if (!vehicle) {
      throw new AppError('Vehicle is not available for this shipment and driver', 422);
    }

    const activeAssignments = await adminShipmentModel.listActiveAssignments(
      shipmentId,
      connection,
    );
    await adminShipmentModel.cancelAssignments(
      {
        shipmentId,
        reason: notes || 'Reassigned by admin',
      },
      connection,
    );
    await releaseCancelledAssignments(
      {
        assignments: activeAssignments,
        shipmentId,
      },
      connection,
    );

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

    await adminShipmentModel.updateDriverAvailability(
      driverId,
      'busy',
      connection,
    );
    await adminShipmentModel.updateVehicleAssignment(
      {
        vehicleId,
        availabilityStatus: 'assigned',
        assignedDriverId: driverId,
      },
      connection,
    );

    await writeShipmentAudit(
      {
        action: activeAssignments.length
          ? 'shipment.reassigned'
          : 'shipment.assigned',
        actorUserId,
        shipmentId,
        oldValues: {
          shipmentStatus: shipment.shipmentStatus,
          activeAssignments,
        },
        newValues: {
          shipmentStatus: updatedShipment.shipmentStatus,
          assignment,
          notes: notes || null,
        },
        requestMeta,
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
      message: activeAssignments.length
        ? 'Shipment reassigned successfully.'
        : 'Shipment assigned successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  approveShipment,
  cancelShipment,
  getShipmentDetails,
  listShipments,
  reassignShipment,
  rejectShipment,
};
