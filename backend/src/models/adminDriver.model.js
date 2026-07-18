const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => Number(value || 0);

const mapDriver = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    rating: Number(row.rating || 0),
    completedTrips: toNumber(row.completedTrips),
    assignmentCount: toNumber(row.assignmentCount),
    activeAssignments: toNumber(row.activeAssignments),
    completedAssignments: toNumber(row.completedAssignments),
    assignedVehicleCapacityKg:
      row.assignedVehicleCapacityKg === null
        ? null
        : Number(row.assignedVehicleCapacityKg),
  };
};

const driverColumns = `
  d.id,
  d.driver_code AS driverCode,
  d.user_id AS userId,
  u.public_id AS userPublicId,
  u.name,
  u.username,
  u.email,
  u.phone,
  u.avatar_url AS avatarUrl,
  u.status AS userStatus,
  u.last_login_at AS lastLoginAt,
  d.license_number AS licenseNumber,
  d.license_expiry_date AS licenseExpiryDate,
  d.address_line1 AS addressLine1,
  d.address_line2 AS addressLine2,
  d.city,
  d.state,
  d.postal_code AS postalCode,
  d.availability_status AS availabilityStatus,
  d.driver_status AS driverStatus,
  d.rating,
  d.completed_trips AS completedTrips,
  d.emergency_contact_name AS emergencyContactName,
  d.emergency_contact_phone AS emergencyContactPhone,
  d.created_at AS createdAt,
  d.updated_at AS updatedAt,
  (
    SELECT COUNT(*)
    FROM assignments a
    WHERE a.driver_id = d.id AND a.deleted_at IS NULL
  ) AS assignmentCount,
  (
    SELECT COUNT(*)
    FROM assignments a
    WHERE a.driver_id = d.id
      AND a.assignment_status IN ('assigned', 'accepted', 'started', 'pickup_completed', 'in_transit')
      AND a.deleted_at IS NULL
  ) AS activeAssignments,
  (
    SELECT COUNT(*)
    FROM assignments a
    WHERE a.driver_id = d.id
      AND a.assignment_status = 'completed'
      AND a.deleted_at IS NULL
  ) AS completedAssignments,
  (
    SELECT v.id
    FROM vehicles v
    WHERE v.assigned_driver_id = d.id AND v.deleted_at IS NULL
    ORDER BY v.updated_at DESC
    LIMIT 1
  ) AS assignedVehicleId,
  (
    SELECT v.vehicle_number
    FROM vehicles v
    WHERE v.assigned_driver_id = d.id AND v.deleted_at IS NULL
    ORDER BY v.updated_at DESC
    LIMIT 1
  ) AS assignedVehicleNumber,
  (
    SELECT v.registration_number
    FROM vehicles v
    WHERE v.assigned_driver_id = d.id AND v.deleted_at IS NULL
    ORDER BY v.updated_at DESC
    LIMIT 1
  ) AS assignedVehicleRegistrationNumber,
  (
    SELECT v.vehicle_type
    FROM vehicles v
    WHERE v.assigned_driver_id = d.id AND v.deleted_at IS NULL
    ORDER BY v.updated_at DESC
    LIMIT 1
  ) AS assignedVehicleType,
  (
    SELECT v.capacity_kg
    FROM vehicles v
    WHERE v.assigned_driver_id = d.id AND v.deleted_at IS NULL
    ORDER BY v.updated_at DESC
    LIMIT 1
  ) AS assignedVehicleCapacityKg
`;

const buildDriverFilters = (filters = {}) => {
  const where = [
    'd.deleted_at IS NULL',
    'u.deleted_at IS NULL',
    "u.role = 'driver'",
  ];
  const values = [];

  if (filters.search) {
    where.push(`(
      d.driver_code LIKE ?
      OR d.license_number LIKE ?
      OR u.name LIKE ?
      OR u.username LIKE ?
      OR u.email LIKE ?
      OR u.phone LIKE ?
      OR d.city LIKE ?
      OR d.state LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search, search, search, search);
  }

  if (filters.driverStatus) {
    where.push('d.driver_status = ?');
    values.push(filters.driverStatus);
  }

  if (filters.availabilityStatus) {
    where.push('d.availability_status = ?');
    values.push(filters.availabilityStatus);
  }

  if (filters.licenseExpiryFrom) {
    where.push('DATE(d.license_expiry_date) >= DATE(?)');
    values.push(filters.licenseExpiryFrom);
  }

  if (filters.licenseExpiryTo) {
    where.push('DATE(d.license_expiry_date) <= DATE(?)');
    values.push(filters.licenseExpiryTo);
  }

  if (filters.city) {
    where.push('d.city = ?');
    values.push(filters.city);
  }

  if (filters.state) {
    where.push('d.state = ?');
    values.push(filters.state);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const listDrivers = async (
  { filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildDriverFilters(filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM drivers d
      INNER JOIN users u ON u.id = d.user_id
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${driverColumns}
      FROM drivers d
      INNER JOIN users u ON u.id = d.user_id
      WHERE ${whereSql}
      ORDER BY d.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapDriver),
    total: toNumber(firstRow(countRows).total),
  };
};

const findById = async (driverId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${driverColumns}
      FROM drivers d
      INNER JOIN users u ON u.id = d.user_id
      WHERE d.id = ?
        AND d.deleted_at IS NULL
        AND u.deleted_at IS NULL
        AND u.role = 'driver'
      LIMIT 1
    `,
    [driverId],
  );

  return mapDriver(firstRow(rows));
};

const findByLicenseNumber = async (licenseNumber, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT id, license_number AS licenseNumber
      FROM drivers
      WHERE license_number = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [licenseNumber],
  );

  return firstRow(rows);
};

const createDriver = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO drivers (
        user_id, driver_code, license_number, license_expiry_date,
        address_line1, address_line2, city, state, postal_code,
        availability_status, driver_status, emergency_contact_name,
        emergency_contact_phone
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.userId,
      payload.driverCode,
      payload.licenseNumber,
      payload.licenseExpiryDate,
      payload.addressLine1 || null,
      payload.addressLine2 || null,
      payload.city || null,
      payload.state || null,
      payload.postalCode || null,
      payload.availabilityStatus || 'available',
      payload.driverStatus || 'active',
      payload.emergencyContactName || null,
      payload.emergencyContactPhone || null,
    ],
  );

  return findById(result.insertId, connection);
};

const updateUserFields = async ({ userId, payload }, connection = null) => {
  const executor = getExecutor(connection);
  const updates = [];
  const values = [];

  [
    ['name', payload.name],
    ['username', payload.username],
    ['email', payload.email],
    ['phone', payload.phone],
    ['password_hash', payload.passwordHash],
    ['status', payload.userStatus],
  ].forEach(([column, value]) => {
    if (value !== undefined) {
      updates.push(`${column} = ?`);
      values.push(value);
    }
  });

  if (updates.length === 0) {
    return;
  }

  await executor.execute(
    `
      UPDATE users
      SET ${updates.join(', ')}
      WHERE id = ?
        AND deleted_at IS NULL
        AND role = 'driver'
    `,
    [...values, userId],
  );
};

const updateDriverFields = async ({ driverId, payload }, connection = null) => {
  const executor = getExecutor(connection);
  const updates = [];
  const values = [];

  [
    ['license_number', payload.licenseNumber],
    ['license_expiry_date', payload.licenseExpiryDate],
    ['address_line1', payload.addressLine1],
    ['address_line2', payload.addressLine2],
    ['city', payload.city],
    ['state', payload.state],
    ['postal_code', payload.postalCode],
    ['availability_status', payload.availabilityStatus],
    ['driver_status', payload.driverStatus],
    ['emergency_contact_name', payload.emergencyContactName],
    ['emergency_contact_phone', payload.emergencyContactPhone],
  ].forEach(([column, value]) => {
    if (value !== undefined) {
      updates.push(`${column} = ?`);
      values.push(value);
    }
  });

  if (updates.length === 0) {
    return findById(driverId, connection);
  }

  await executor.execute(
    `
      UPDATE drivers
      SET ${updates.join(', ')}
      WHERE id = ? AND deleted_at IS NULL
    `,
    [...values, driverId],
  );

  return findById(driverId, connection);
};

const updateStatus = async (
  { driverId, driverStatus, availabilityStatus, userStatus },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE drivers d
      INNER JOIN users u ON u.id = d.user_id
      SET d.driver_status = ?,
          d.availability_status = ?,
          u.status = ?
      WHERE d.id = ?
        AND d.deleted_at IS NULL
        AND u.deleted_at IS NULL
        AND u.role = 'driver'
    `,
    [driverStatus, availabilityStatus, userStatus, driverId],
  );

  return findById(driverId, connection);
};

const listRecentAssignments = async (
  { driverId, limit = 5 },
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
        s.shipment_status AS shipmentStatus,
        v.vehicle_number AS vehicleNumber
      FROM assignments a
      INNER JOIN shipments s ON s.id = a.shipment_id
      INNER JOIN vehicles v ON v.id = a.vehicle_id
      WHERE a.driver_id = ?
        AND a.deleted_at IS NULL
      ORDER BY a.assigned_at DESC
      LIMIT ?
    `,
    [driverId, Number(limit)],
  );

  return rows;
};

module.exports = {
  createDriver,
  findById,
  findByLicenseNumber,
  listDrivers,
  listRecentAssignments,
  updateDriverFields,
  updateStatus,
  updateUserFields,
};
