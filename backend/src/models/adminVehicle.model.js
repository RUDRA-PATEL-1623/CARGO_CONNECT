const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => (value === null || value === undefined ? null : Number(value));

const mapVehicle = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    capacityKg: toNumber(row.capacityKg),
    assignmentCount: Number(row.assignmentCount || 0),
    activeAssignments: Number(row.activeAssignments || 0),
    completedAssignments: Number(row.completedAssignments || 0),
    assignedDriverRating: toNumber(row.assignedDriverRating),
  };
};

const vehicleColumns = `
  v.id,
  v.vehicle_number AS vehicleNumber,
  v.registration_number AS registrationNumber,
  v.vehicle_type AS vehicleType,
  v.model,
  v.capacity_kg AS capacityKg,
  v.fuel_type AS fuelType,
  v.insurance_expiry_date AS insuranceExpiryDate,
  v.service_due_date AS serviceDueDate,
  v.availability_status AS availabilityStatus,
  v.assigned_driver_id AS assignedDriverId,
  v.notes,
  v.created_at AS createdAt,
  v.updated_at AS updatedAt,
  d.driver_code AS assignedDriverCode,
  d.rating AS assignedDriverRating,
  du.name AS assignedDriverName,
  du.phone AS assignedDriverPhone,
  (
    SELECT COUNT(*)
    FROM assignments a
    WHERE a.vehicle_id = v.id AND a.deleted_at IS NULL
  ) AS assignmentCount,
  (
    SELECT COUNT(*)
    FROM assignments a
    WHERE a.vehicle_id = v.id
      AND a.assignment_status IN ('assigned', 'accepted', 'started', 'pickup_completed', 'in_transit')
      AND a.deleted_at IS NULL
  ) AS activeAssignments,
  (
    SELECT COUNT(*)
    FROM assignments a
    WHERE a.vehicle_id = v.id
      AND a.assignment_status = 'completed'
      AND a.deleted_at IS NULL
  ) AS completedAssignments
`;

const buildVehicleFilters = (filters = {}) => {
  const where = ['v.deleted_at IS NULL'];
  const values = [];

  if (filters.search) {
    where.push(`(
      v.vehicle_number LIKE ?
      OR v.registration_number LIKE ?
      OR v.model LIKE ?
      OR d.driver_code LIKE ?
      OR du.name LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search);
  }

  if (filters.vehicleType) {
    where.push('v.vehicle_type = ?');
    values.push(filters.vehicleType);
  }

  if (filters.fuelType) {
    where.push('v.fuel_type = ?');
    values.push(filters.fuelType);
  }

  if (filters.availabilityStatus) {
    where.push('v.availability_status = ?');
    values.push(filters.availabilityStatus);
  }

  if (filters.assignedDriverId) {
    where.push('v.assigned_driver_id = ?');
    values.push(filters.assignedDriverId);
  }

  if (filters.insuranceExpiryFrom) {
    where.push('DATE(v.insurance_expiry_date) >= DATE(?)');
    values.push(filters.insuranceExpiryFrom);
  }

  if (filters.insuranceExpiryTo) {
    where.push('DATE(v.insurance_expiry_date) <= DATE(?)');
    values.push(filters.insuranceExpiryTo);
  }

  if (filters.serviceDueFrom) {
    where.push('DATE(v.service_due_date) >= DATE(?)');
    values.push(filters.serviceDueFrom);
  }

  if (filters.serviceDueTo) {
    where.push('DATE(v.service_due_date) <= DATE(?)');
    values.push(filters.serviceDueTo);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const listVehicles = async (
  { filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildVehicleFilters(filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM vehicles v
      LEFT JOIN drivers d ON d.id = v.assigned_driver_id AND d.deleted_at IS NULL
      LEFT JOIN users du ON du.id = d.user_id AND du.deleted_at IS NULL
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${vehicleColumns}
      FROM vehicles v
      LEFT JOIN drivers d ON d.id = v.assigned_driver_id AND d.deleted_at IS NULL
      LEFT JOIN users du ON du.id = d.user_id AND du.deleted_at IS NULL
      WHERE ${whereSql}
      ORDER BY v.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapVehicle),
    total: Number(firstRow(countRows).total || 0),
  };
};

const findById = async (vehicleId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${vehicleColumns}
      FROM vehicles v
      LEFT JOIN drivers d ON d.id = v.assigned_driver_id AND d.deleted_at IS NULL
      LEFT JOIN users du ON du.id = d.user_id AND du.deleted_at IS NULL
      WHERE v.id = ?
        AND v.deleted_at IS NULL
      LIMIT 1
    `,
    [vehicleId],
  );

  return mapVehicle(firstRow(rows));
};

const findByVehicleNumber = async (vehicleNumber, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT id, vehicle_number AS vehicleNumber
      FROM vehicles
      WHERE vehicle_number = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [vehicleNumber],
  );

  return firstRow(rows);
};

const findByRegistrationNumber = async (registrationNumber, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT id, registration_number AS registrationNumber
      FROM vehicles
      WHERE registration_number = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [registrationNumber],
  );

  return firstRow(rows);
};

const findAssignableDriver = async (driverId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT id, driver_code AS driverCode
      FROM drivers
      WHERE id = ?
        AND driver_status = 'active'
        AND deleted_at IS NULL
      LIMIT 1
    `,
    [driverId],
  );

  return firstRow(rows);
};

const createVehicle = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO vehicles (
        vehicle_number, registration_number, vehicle_type, model,
        capacity_kg, fuel_type, insurance_expiry_date, service_due_date,
        availability_status, assigned_driver_id, notes
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.vehicleNumber,
      payload.registrationNumber,
      payload.vehicleType,
      payload.model || null,
      payload.capacityKg,
      payload.fuelType,
      payload.insuranceExpiryDate || null,
      payload.serviceDueDate || null,
      payload.availabilityStatus || 'available',
      payload.assignedDriverId || null,
      payload.notes || null,
    ],
  );

  return findById(result.insertId, connection);
};

const updateVehicleFields = async ({ vehicleId, payload }, connection = null) => {
  const executor = getExecutor(connection);
  const updates = [];
  const values = [];

  [
    ['vehicle_number', payload.vehicleNumber],
    ['registration_number', payload.registrationNumber],
    ['vehicle_type', payload.vehicleType],
    ['model', payload.model],
    ['capacity_kg', payload.capacityKg],
    ['fuel_type', payload.fuelType],
    ['insurance_expiry_date', payload.insuranceExpiryDate],
    ['service_due_date', payload.serviceDueDate],
    ['availability_status', payload.availabilityStatus],
    ['assigned_driver_id', payload.assignedDriverId],
    ['notes', payload.notes],
  ].forEach(([column, value]) => {
    if (value !== undefined) {
      updates.push(`${column} = ?`);
      values.push(value);
    }
  });

  if (updates.length === 0) {
    return findById(vehicleId, connection);
  }

  await executor.execute(
    `
      UPDATE vehicles
      SET ${updates.join(', ')}
      WHERE id = ? AND deleted_at IS NULL
    `,
    [...values, vehicleId],
  );

  return findById(vehicleId, connection);
};

const updateAvailability = async (
  { vehicleId, availabilityStatus, assignedDriverId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE vehicles
      SET availability_status = ?,
          assigned_driver_id = ?
      WHERE id = ? AND deleted_at IS NULL
    `,
    [availabilityStatus, assignedDriverId, vehicleId],
  );

  return findById(vehicleId, connection);
};

const listRecentAssignments = async (
  { vehicleId, limit = 5 },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        a.id,
        a.assignment_code AS assignmentCode,
        a.assignment_status AS assignmentStatus,
        a.assigned_at AS assignedAt,
        a.accepted_at AS acceptedAt,
        a.started_at AS startedAt,
        a.completed_at AS completedAt,
        s.id AS shipmentId,
        s.shipment_code AS shipmentCode,
        s.pickup_address AS pickupAddress,
        s.delivery_address AS deliveryAddress,
        d.driver_code AS driverCode,
        du.name AS driverName
      FROM assignments a
      INNER JOIN shipments s ON s.id = a.shipment_id
      INNER JOIN drivers d ON d.id = a.driver_id
      INNER JOIN users du ON du.id = d.user_id
      WHERE a.vehicle_id = ?
        AND a.deleted_at IS NULL
      ORDER BY a.assigned_at DESC
      LIMIT ?
    `,
    [vehicleId, Number(limit)],
  );

  return rows;
};

module.exports = {
  createVehicle,
  findAssignableDriver,
  findById,
  findByRegistrationNumber,
  findByVehicleNumber,
  listRecentAssignments,
  listVehicles,
  updateAvailability,
  updateVehicleFields,
};
