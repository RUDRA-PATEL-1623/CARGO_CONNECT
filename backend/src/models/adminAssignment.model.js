const { getPool } = require('../config/database');

const { ACTIVE_ASSIGNMENT_STATUSES } = require('./adminShipment.model');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => (value === null || value === undefined ? null : Number(value));

const mapAssignment = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    driverRating: toNumber(row.driverRating),
    vehicleCapacityKg: toNumber(row.vehicleCapacityKg),
  };
};

const assignmentColumns = `
  a.id,
  a.assignment_code AS assignmentCode,
  a.shipment_id AS shipmentId,
  s.shipment_code AS shipmentCode,
  s.shipment_status AS shipmentStatus,
  c.user_id AS customerUserId,
  a.driver_id AS driverId,
  d.user_id AS driverUserId,
  d.driver_code AS driverCode,
  du.name AS driverName,
  du.phone AS driverPhone,
  d.rating AS driverRating,
  d.availability_status AS driverAvailabilityStatus,
  a.vehicle_id AS vehicleId,
  v.vehicle_number AS vehicleNumber,
  v.registration_number AS vehicleRegistrationNumber,
  v.vehicle_type AS vehicleType,
  v.capacity_kg AS vehicleCapacityKg,
  v.availability_status AS vehicleAvailabilityStatus,
  a.assigned_by_user_id AS assignedByUserId,
  au.name AS assignedByName,
  a.assignment_status AS assignmentStatus,
  a.assigned_at AS assignedAt,
  a.accepted_at AS acceptedAt,
  a.rejected_at AS rejectedAt,
  a.rejection_reason AS rejectionReason,
  a.started_at AS startedAt,
  a.completed_at AS completedAt,
  a.created_at AS createdAt,
  a.updated_at AS updatedAt
`;

const activeStatusPlaceholders = ACTIVE_ASSIGNMENT_STATUSES
  .map(() => '?')
  .join(', ');

const findById = async (assignmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${assignmentColumns}
      FROM assignments a
      INNER JOIN shipments s ON s.id = a.shipment_id
      INNER JOIN customers c ON c.id = s.customer_id
      INNER JOIN drivers d ON d.id = a.driver_id
      INNER JOIN users du ON du.id = d.user_id
      INNER JOIN vehicles v ON v.id = a.vehicle_id
      LEFT JOIN users au ON au.id = a.assigned_by_user_id
      WHERE a.id = ?
        AND a.deleted_at IS NULL
      LIMIT 1
    `,
    [assignmentId],
  );

  return mapAssignment(firstRow(rows));
};

const findDriver = async (driverId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        d.id,
        d.driver_code AS driverCode,
        d.availability_status AS availabilityStatus,
        d.driver_status AS driverStatus,
        du.name AS driverName
      FROM drivers d
      INNER JOIN users du ON du.id = d.user_id
      WHERE d.id = ?
        AND d.deleted_at IS NULL
        AND du.deleted_at IS NULL
      LIMIT 1
    `,
    [driverId],
  );

  return firstRow(rows);
};

const findVehicle = async (vehicleId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        id,
        vehicle_number AS vehicleNumber,
        registration_number AS registrationNumber,
        availability_status AS availabilityStatus,
        assigned_driver_id AS assignedDriverId
      FROM vehicles
      WHERE id = ?
        AND deleted_at IS NULL
      LIMIT 1
    `,
    [vehicleId],
  );

  return firstRow(rows);
};

const listDriverConflicts = async (
  { driverId, excludedShipmentId = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        a.id AS assignmentId,
        a.assignment_code AS assignmentCode,
        a.assignment_status AS assignmentStatus,
        s.id AS shipmentId,
        s.shipment_code AS shipmentCode
      FROM assignments a
      INNER JOIN shipments s ON s.id = a.shipment_id
      WHERE a.driver_id = ?
        AND (? IS NULL OR a.shipment_id <> ?)
        AND a.assignment_status IN (${activeStatusPlaceholders})
        AND a.deleted_at IS NULL
      ORDER BY a.assigned_at DESC
    `,
    [driverId, excludedShipmentId, excludedShipmentId, ...ACTIVE_ASSIGNMENT_STATUSES],
  );

  return rows;
};

const listVehicleConflicts = async (
  { vehicleId, excludedShipmentId = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        a.id AS assignmentId,
        a.assignment_code AS assignmentCode,
        a.assignment_status AS assignmentStatus,
        s.id AS shipmentId,
        s.shipment_code AS shipmentCode
      FROM assignments a
      INNER JOIN shipments s ON s.id = a.shipment_id
      WHERE a.vehicle_id = ?
        AND (? IS NULL OR a.shipment_id <> ?)
        AND a.assignment_status IN (${activeStatusPlaceholders})
        AND a.deleted_at IS NULL
      ORDER BY a.assigned_at DESC
    `,
    [vehicleId, excludedShipmentId, excludedShipmentId, ...ACTIVE_ASSIGNMENT_STATUSES],
  );

  return rows;
};

module.exports = {
  findById,
  findDriver,
  findVehicle,
  listDriverConflicts,
  listVehicleConflicts,
};
