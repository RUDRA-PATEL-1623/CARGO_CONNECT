const { getPool } = require('../config/database');

const ACTIVE_ASSIGNMENT_STATUSES = [
  'assigned',
  'accepted',
  'started',
  'pickup_completed',
  'in_transit',
  'delivered',
];

const TRIP_GROUPS = Object.freeze({
  new: ['assigned'],
  accepted: ['accepted'],
  in_progress: ['started', 'pickup_completed', 'in_transit', 'delivered'],
  completed: ['completed'],
  rejected: ['rejected'],
  history: ['completed', 'rejected', 'cancelled'],
});

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => (value === null || value === undefined ? null : Number(value));

const toBoolean = (value) => Boolean(value);

const mapTrip = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    packageWeightKg: toNumber(row.packageWeightKg),
    packageLengthCm: toNumber(row.packageLengthCm),
    packageWidthCm: toNumber(row.packageWidthCm),
    packageHeightCm: toNumber(row.packageHeightCm),
    estimatedDistanceKm: toNumber(row.estimatedDistanceKm),
    estimatedPrice: toNumber(row.estimatedPrice),
    isFragile: toBoolean(row.isFragile),
    driverRating: toNumber(row.driverRating),
    vehicleCapacityKg: toNumber(row.vehicleCapacityKg),
  };
};

const mapTripLog = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    latitude: toNumber(row.latitude),
    longitude: toNumber(row.longitude),
  };
};

const mapProof = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    latitude: toNumber(row.latitude),
    longitude: toNumber(row.longitude),
    fileSizeBytes: row.fileSizeBytes === null ? null : Number(row.fileSizeBytes),
  };
};

const tripColumns = `
  a.id AS assignmentId,
  a.assignment_code AS assignmentCode,
  a.shipment_id AS shipmentId,
  a.driver_id AS driverId,
  a.vehicle_id AS vehicleId,
  a.assignment_status AS assignmentStatus,
  a.assigned_at AS assignedAt,
  a.accepted_at AS acceptedAt,
  a.rejected_at AS rejectedAt,
  a.rejection_reason AS rejectionReason,
  a.started_at AS startedAt,
  a.completed_at AS assignmentCompletedAt,
  a.created_at AS assignmentCreatedAt,
  a.updated_at AS assignmentUpdatedAt,
  s.shipment_code AS shipmentCode,
  s.customer_id AS customerId,
  c.user_id AS customerUserId,
  c.customer_code AS customerCode,
  cu.name AS customerName,
  cu.email AS customerEmail,
  cu.phone AS customerPhone,
  s.category_id AS categoryId,
  sc.code AS categoryCode,
  sc.name AS categoryName,
  sc.icon_key AS categoryIconKey,
  s.pickup_address AS pickupAddress,
  s.pickup_city AS pickupCity,
  s.pickup_state AS pickupState,
  s.pickup_postal_code AS pickupPostalCode,
  s.delivery_address AS deliveryAddress,
  s.delivery_city AS deliveryCity,
  s.delivery_state AS deliveryState,
  s.delivery_postal_code AS deliveryPostalCode,
  s.receiver_name AS receiverName,
  s.receiver_phone AS receiverPhone,
  s.package_type AS packageType,
  s.package_weight_kg AS packageWeightKg,
  s.package_length_cm AS packageLengthCm,
  s.package_width_cm AS packageWidthCm,
  s.package_height_cm AS packageHeightCm,
  s.vehicle_preference AS vehiclePreference,
  s.is_fragile AS isFragile,
  s.delivery_notes AS deliveryNotes,
  s.scheduled_pickup_at AS pickupDateTime,
  s.estimated_distance_km AS estimatedDistanceKm,
  s.estimated_duration_minutes AS estimatedDurationMinutes,
  s.estimated_price AS estimatedPrice,
  s.shipment_status AS shipmentStatus,
  s.payment_status AS paymentStatus,
  s.approved_at AS approvedAt,
  s.cancelled_at AS cancelledAt,
  s.cancellation_reason AS cancellationReason,
  s.completed_at AS shipmentCompletedAt,
  s.created_at AS shipmentCreatedAt,
  s.updated_at AS shipmentUpdatedAt,
  d.driver_code AS driverCode,
  du.name AS driverName,
  du.phone AS driverPhone,
  d.rating AS driverRating,
  d.availability_status AS driverAvailabilityStatus,
  v.vehicle_number AS vehicleNumber,
  v.registration_number AS vehicleRegistrationNumber,
  v.vehicle_type AS vehicleType,
  v.model AS vehicleModel,
  v.capacity_kg AS vehicleCapacityKg,
  v.fuel_type AS vehicleFuelType,
  v.availability_status AS vehicleAvailabilityStatus
`;

const buildTripFilters = (driverId, filters = {}) => {
  const where = [
    'a.driver_id = ?',
    'a.deleted_at IS NULL',
    's.deleted_at IS NULL',
    'c.deleted_at IS NULL',
    'cu.deleted_at IS NULL',
    'sc.deleted_at IS NULL',
    'd.deleted_at IS NULL',
    'du.deleted_at IS NULL',
    'v.deleted_at IS NULL',
  ];
  const values = [driverId];

  if (filters.group && TRIP_GROUPS[filters.group]) {
    where.push(
      `a.assignment_status IN (${TRIP_GROUPS[filters.group].map(() => '?').join(', ')})`,
    );
    values.push(...TRIP_GROUPS[filters.group]);
  }

  if (filters.status) {
    where.push('a.assignment_status = ?');
    values.push(filters.status);
  }

  if (filters.shipmentStatus) {
    where.push('s.shipment_status = ?');
    values.push(filters.shipmentStatus);
  }

  if (filters.search) {
    where.push(`(
      a.assignment_code LIKE ?
      OR s.shipment_code LIKE ?
      OR s.pickup_address LIKE ?
      OR s.delivery_address LIKE ?
      OR s.receiver_name LIKE ?
      OR s.package_type LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search, search);
  }

  if (filters.dateFrom) {
    where.push('DATE(s.scheduled_pickup_at) >= DATE(?)');
    values.push(filters.dateFrom);
  }

  if (filters.dateTo) {
    where.push('DATE(s.scheduled_pickup_at) <= DATE(?)');
    values.push(filters.dateTo);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const listTrips = async (
  { driverId, filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildTripFilters(driverId, filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM assignments a
      INNER JOIN shipments s ON s.id = a.shipment_id
      INNER JOIN customers c ON c.id = s.customer_id
      INNER JOIN users cu ON cu.id = c.user_id
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      INNER JOIN drivers d ON d.id = a.driver_id
      INNER JOIN users du ON du.id = d.user_id
      INNER JOIN vehicles v ON v.id = a.vehicle_id
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${tripColumns}
      FROM assignments a
      INNER JOIN shipments s ON s.id = a.shipment_id
      INNER JOIN customers c ON c.id = s.customer_id
      INNER JOIN users cu ON cu.id = c.user_id
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      INNER JOIN drivers d ON d.id = a.driver_id
      INNER JOIN users du ON du.id = d.user_id
      INNER JOIN vehicles v ON v.id = a.vehicle_id
      WHERE ${whereSql}
      ORDER BY
        CASE a.assignment_status
          WHEN 'assigned' THEN 0
          WHEN 'accepted' THEN 1
          WHEN 'started' THEN 2
          WHEN 'pickup_completed' THEN 3
          WHEN 'in_transit' THEN 4
          WHEN 'delivered' THEN 5
          WHEN 'completed' THEN 6
          ELSE 7
        END,
        s.scheduled_pickup_at ASC,
        a.assigned_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapTrip),
    total: Number(firstRow(countRows).total || 0),
  };
};

const findTripById = async (
  { driverId, assignmentId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${tripColumns}
      FROM assignments a
      INNER JOIN shipments s ON s.id = a.shipment_id
      INNER JOIN customers c ON c.id = s.customer_id
      INNER JOIN users cu ON cu.id = c.user_id
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      INNER JOIN drivers d ON d.id = a.driver_id
      INNER JOIN users du ON du.id = d.user_id
      INNER JOIN vehicles v ON v.id = a.vehicle_id
      WHERE a.id = ?
        AND a.driver_id = ?
        AND a.deleted_at IS NULL
        AND s.deleted_at IS NULL
        AND c.deleted_at IS NULL
        AND cu.deleted_at IS NULL
        AND sc.deleted_at IS NULL
        AND d.deleted_at IS NULL
        AND du.deleted_at IS NULL
        AND v.deleted_at IS NULL
      LIMIT 1
    `,
    [assignmentId, driverId],
  );

  return mapTrip(firstRow(rows));
};

const updateAssignmentAccepted = async (
  { assignmentId, driverId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      UPDATE assignments
      SET assignment_status = 'accepted',
          accepted_at = CURRENT_TIMESTAMP,
          rejection_reason = NULL
      WHERE id = ?
        AND driver_id = ?
        AND assignment_status = 'assigned'
        AND deleted_at IS NULL
    `,
    [assignmentId, driverId],
  );

  return result.affectedRows;
};

const updateAssignmentRejected = async (
  { assignmentId, driverId, reason },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      UPDATE assignments
      SET assignment_status = 'rejected',
          rejected_at = CURRENT_TIMESTAMP,
          rejection_reason = ?
      WHERE id = ?
        AND driver_id = ?
        AND assignment_status = 'assigned'
        AND deleted_at IS NULL
    `,
    [reason, assignmentId, driverId],
  );

  return result.affectedRows;
};

const updateAssignmentStatus = async (
  { assignmentId, driverId, fromStatus, toStatus },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const timestampSqlByStatus = {
    started: ', started_at = CURRENT_TIMESTAMP',
    completed: ', completed_at = CURRENT_TIMESTAMP',
  };

  const [result] = await executor.execute(
    `
      UPDATE assignments
      SET assignment_status = ?
          ${timestampSqlByStatus[toStatus] || ''}
      WHERE id = ?
        AND driver_id = ?
        AND assignment_status = ?
        AND deleted_at IS NULL
    `,
    [toStatus, assignmentId, driverId, fromStatus],
  );

  return result.affectedRows;
};

const updateShipmentStatus = async (
  { shipmentId, status, markCompleted = false },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE shipments
      SET shipment_status = ?,
          completed_at = CASE WHEN ? THEN CURRENT_TIMESTAMP ELSE completed_at END
      WHERE id = ? AND deleted_at IS NULL
    `,
    [status, markCompleted ? 1 : 0, shipmentId],
  );
};

const countActiveDriverAssignments = async (
  { driverId, excludedAssignmentId = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM assignments
      WHERE driver_id = ?
        AND (? IS NULL OR id <> ?)
        AND assignment_status IN (${ACTIVE_ASSIGNMENT_STATUSES.map(() => '?').join(', ')})
        AND deleted_at IS NULL
    `,
    [
      driverId,
      excludedAssignmentId,
      excludedAssignmentId,
      ...ACTIVE_ASSIGNMENT_STATUSES,
    ],
  );

  return Number(firstRow(rows).total || 0);
};

const countActiveVehicleAssignments = async (
  { vehicleId, excludedAssignmentId = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM assignments
      WHERE vehicle_id = ?
        AND (? IS NULL OR id <> ?)
        AND assignment_status IN (${ACTIVE_ASSIGNMENT_STATUSES.map(() => '?').join(', ')})
        AND deleted_at IS NULL
    `,
    [
      vehicleId,
      excludedAssignmentId,
      excludedAssignmentId,
      ...ACTIVE_ASSIGNMENT_STATUSES,
    ],
  );

  return Number(firstRow(rows).total || 0);
};

const updateDriverAvailability = async (
  { driverId, availabilityStatus },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE drivers
      SET availability_status = ?
      WHERE id = ? AND deleted_at IS NULL
    `,
    [availabilityStatus, driverId],
  );
};

const updateVehicleAssignment = async (
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
};

const createTripLog = async (
  {
    shipmentId,
    assignmentId,
    driverId,
    vehicleId,
    status,
    title,
    description,
    locationText,
    latitude,
    longitude,
  },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO trip_logs (
        shipment_id, assignment_id, driver_id, vehicle_id,
        status, title, description, location_text, latitude, longitude
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      shipmentId,
      assignmentId,
      driverId,
      vehicleId,
      status,
      title,
      description || null,
      locationText || null,
      latitude ?? null,
      longitude ?? null,
    ],
  );

  return {
    id: result.insertId,
  };
};

const incrementDriverCompletedTrips = async (driverId, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE drivers
      SET completed_trips = completed_trips + 1
      WHERE id = ? AND deleted_at IS NULL
    `,
    [driverId],
  );
};

const listTripLogs = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        id,
        shipment_id AS shipmentId,
        assignment_id AS assignmentId,
        driver_id AS driverId,
        vehicle_id AS vehicleId,
        status,
        title,
        description,
        location_text AS locationText,
        latitude,
        longitude,
        event_time AS eventTime,
        created_at AS createdAt
      FROM trip_logs
      WHERE shipment_id = ?
        AND deleted_at IS NULL
      ORDER BY event_time ASC, id ASC
    `,
    [shipmentId],
  );

  return rows.map(mapTripLog);
};

const listProofs = async (
  { shipmentId, assignmentId, driverId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        p.id,
        p.proof_code AS proofCode,
        p.shipment_id AS shipmentId,
        p.assignment_id AS assignmentId,
        p.uploaded_by_driver_id AS uploadedByDriverId,
        p.proof_type AS proofType,
        p.file_url AS fileUrl,
        p.file_name AS fileName,
        p.file_mime_type AS fileMimeType,
        p.file_size_bytes AS fileSizeBytes,
        p.notes,
        p.location_text AS locationText,
        p.latitude,
        p.longitude,
        p.verification_status AS verificationStatus,
        p.verified_at AS verifiedAt,
        p.captured_at AS capturedAt,
        p.created_at AS createdAt
      FROM proof_uploads p
      WHERE p.shipment_id = ?
        AND (p.assignment_id = ? OR p.uploaded_by_driver_id = ?)
        AND p.deleted_at IS NULL
      ORDER BY p.captured_at DESC, p.created_at DESC
    `,
    [shipmentId, assignmentId, driverId],
  );

  return rows.map(mapProof);
};

const findProofById = async (proofId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        p.id,
        p.proof_code AS proofCode,
        p.shipment_id AS shipmentId,
        p.assignment_id AS assignmentId,
        p.uploaded_by_driver_id AS uploadedByDriverId,
        p.proof_type AS proofType,
        p.file_url AS fileUrl,
        p.file_name AS fileName,
        p.file_mime_type AS fileMimeType,
        p.file_size_bytes AS fileSizeBytes,
        p.notes,
        p.location_text AS locationText,
        p.latitude,
        p.longitude,
        p.verification_status AS verificationStatus,
        p.verified_at AS verifiedAt,
        p.captured_at AS capturedAt,
        p.created_at AS createdAt
      FROM proof_uploads p
      WHERE p.id = ?
        AND p.deleted_at IS NULL
      LIMIT 1
    `,
    [proofId],
  );

  return mapProof(firstRow(rows));
};

const findProofByType = async (
  { shipmentId, assignmentId, driverId, proofType },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        p.id,
        p.proof_code AS proofCode,
        p.shipment_id AS shipmentId,
        p.assignment_id AS assignmentId,
        p.uploaded_by_driver_id AS uploadedByDriverId,
        p.proof_type AS proofType,
        p.file_url AS fileUrl,
        p.file_name AS fileName,
        p.file_mime_type AS fileMimeType,
        p.file_size_bytes AS fileSizeBytes,
        p.notes,
        p.location_text AS locationText,
        p.latitude,
        p.longitude,
        p.verification_status AS verificationStatus,
        p.verified_at AS verifiedAt,
        p.captured_at AS capturedAt,
        p.created_at AS createdAt
      FROM proof_uploads p
      WHERE p.shipment_id = ?
        AND p.assignment_id = ?
        AND p.uploaded_by_driver_id = ?
        AND p.proof_type = ?
        AND p.deleted_at IS NULL
      ORDER BY p.captured_at DESC, p.created_at DESC
      LIMIT 1
    `,
    [shipmentId, assignmentId, driverId, proofType],
  );

  return mapProof(firstRow(rows));
};

const createProofUpload = async (
  {
    shipmentId,
    assignmentId,
    driverId,
    proofType,
    fileUrl,
    fileName,
    fileMimeType,
    fileSizeBytes,
    notes,
    locationText,
    latitude,
    longitude,
    capturedAt,
  },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const now = new Date();
  const datePart = now.toISOString().slice(0, 10).replace(/-/g, '');
  const randomPart = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  const proofCode = `PRF-${datePart}-${Date.now().toString().slice(-6)}${randomPart}`;

  const [result] = await executor.execute(
    `
      INSERT INTO proof_uploads (
        proof_code, shipment_id, assignment_id, uploaded_by_driver_id,
        proof_type, file_url, file_name, file_mime_type, file_size_bytes,
        notes, location_text, latitude, longitude, verification_status, captured_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', COALESCE(?, CURRENT_TIMESTAMP))
    `,
    [
      proofCode,
      shipmentId,
      assignmentId,
      driverId,
      proofType,
      fileUrl,
      fileName || null,
      fileMimeType || null,
      fileSizeBytes || null,
      notes || null,
      locationText || null,
      latitude ?? null,
      longitude ?? null,
      capturedAt || null,
    ],
  );

  return findProofById(result.insertId, connection);
};

module.exports = {
  ACTIVE_ASSIGNMENT_STATUSES,
  TRIP_GROUPS,
  countActiveDriverAssignments,
  countActiveVehicleAssignments,
  createProofUpload,
  createTripLog,
  findTripById,
  findProofByType,
  incrementDriverCompletedTrips,
  listProofs,
  listTripLogs,
  listTrips,
  updateAssignmentAccepted,
  updateAssignmentRejected,
  updateAssignmentStatus,
  updateDriverAvailability,
  updateShipmentStatus,
  updateVehicleAssignment,
};
