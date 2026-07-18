const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const ACTIVE_ASSIGNMENT_STATUSES = [
  'assigned',
  'accepted',
  'started',
  'pickup_completed',
  'in_transit',
  'delivered',
];
const ACTIVE_ASSIGNMENT_STATUS_SQL = ACTIVE_ASSIGNMENT_STATUSES
  .map((status) => `'${status}'`)
  .join(', ');

const toNumber = (value) => (value === null || value === undefined ? null : Number(value));

const mapShipment = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    isFragile: Boolean(row.isFragile),
    packageWeightKg: toNumber(row.packageWeightKg),
    packageLengthCm: toNumber(row.packageLengthCm),
    packageWidthCm: toNumber(row.packageWidthCm),
    packageHeightCm: toNumber(row.packageHeightCm),
    estimatedDistanceKm: toNumber(row.estimatedDistanceKm),
    estimatedPrice: toNumber(row.estimatedPrice),
    paymentTotalAmount: toNumber(row.paymentTotalAmount),
  };
};

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

const shipmentColumns = `
  s.id,
  s.shipment_code AS shipmentCode,
  s.customer_id AS customerId,
  c.user_id AS customerUserId,
  cu.name AS customerName,
  cu.email AS customerEmail,
  cu.phone AS customerPhone,
  c.customer_code AS customerCode,
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
  s.approved_by_user_id AS approvedByUserId,
  s.approved_at AS approvedAt,
  s.cancelled_by_user_id AS cancelledByUserId,
  s.cancelled_at AS cancelledAt,
  s.cancellation_reason AS cancellationReason,
  s.completed_at AS completedAt,
  s.created_at AS createdAt,
  s.updated_at AS updatedAt,
  (
    SELECT p.payment_code
    FROM payments p
    WHERE p.shipment_id = s.id AND p.deleted_at IS NULL
    ORDER BY p.created_at DESC
    LIMIT 1
  ) AS paymentCode,
  (
    SELECT p.total_amount
    FROM payments p
    WHERE p.shipment_id = s.id AND p.deleted_at IS NULL
    ORDER BY p.created_at DESC
    LIMIT 1
  ) AS paymentTotalAmount,
  (
    SELECT i.invoice_number
    FROM invoices i
    WHERE i.shipment_id = s.id AND i.deleted_at IS NULL
    ORDER BY i.created_at DESC
    LIMIT 1
  ) AS invoiceNumber,
  (
    SELECT a.id
    FROM assignments a
    WHERE a.shipment_id = s.id
      AND a.assignment_status IN (${ACTIVE_ASSIGNMENT_STATUS_SQL})
      AND a.deleted_at IS NULL
    ORDER BY a.assigned_at DESC, a.id DESC
    LIMIT 1
  ) AS latestAssignmentId,
  (
    SELECT a.assignment_code
    FROM assignments a
    WHERE a.shipment_id = s.id
      AND a.assignment_status IN (${ACTIVE_ASSIGNMENT_STATUS_SQL})
      AND a.deleted_at IS NULL
    ORDER BY a.assigned_at DESC, a.id DESC
    LIMIT 1
  ) AS latestAssignmentCode,
  (
    SELECT a.assignment_status
    FROM assignments a
    WHERE a.shipment_id = s.id
      AND a.assignment_status IN (${ACTIVE_ASSIGNMENT_STATUS_SQL})
      AND a.deleted_at IS NULL
    ORDER BY a.assigned_at DESC, a.id DESC
    LIMIT 1
  ) AS latestAssignmentStatus,
  (
    SELECT du.name
    FROM assignments a
    INNER JOIN drivers d ON d.id = a.driver_id
    INNER JOIN users du ON du.id = d.user_id
    WHERE a.shipment_id = s.id
      AND a.assignment_status IN (${ACTIVE_ASSIGNMENT_STATUS_SQL})
      AND a.deleted_at IS NULL
    ORDER BY a.assigned_at DESC, a.id DESC
    LIMIT 1
  ) AS latestDriverName,
  (
    SELECT v.vehicle_number
    FROM assignments a
    INNER JOIN vehicles v ON v.id = a.vehicle_id
    WHERE a.shipment_id = s.id
      AND a.assignment_status IN (${ACTIVE_ASSIGNMENT_STATUS_SQL})
      AND a.deleted_at IS NULL
    ORDER BY a.assigned_at DESC, a.id DESC
    LIMIT 1
  ) AS latestVehicleNumber,
  (
    SELECT v.registration_number
    FROM assignments a
    INNER JOIN vehicles v ON v.id = a.vehicle_id
    WHERE a.shipment_id = s.id
      AND a.assignment_status IN (${ACTIVE_ASSIGNMENT_STATUS_SQL})
      AND a.deleted_at IS NULL
    ORDER BY a.assigned_at DESC, a.id DESC
    LIMIT 1
  ) AS latestVehicleRegistrationNumber
`;

const assignmentColumns = `
  a.id,
  a.assignment_code AS assignmentCode,
  a.shipment_id AS shipmentId,
  a.driver_id AS driverId,
  d.user_id AS driverUserId,
  d.driver_code AS driverCode,
  du.name AS driverName,
  du.phone AS driverPhone,
  d.rating AS driverRating,
  a.vehicle_id AS vehicleId,
  v.vehicle_number AS vehicleNumber,
  v.registration_number AS vehicleRegistrationNumber,
  v.vehicle_type AS vehicleType,
  v.capacity_kg AS vehicleCapacityKg,
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

const buildFilters = (filters = {}) => {
  const where = ['s.deleted_at IS NULL'];
  const values = [];

  if (filters.search) {
    where.push(`(
      s.shipment_code LIKE ?
      OR cu.name LIKE ?
      OR cu.email LIKE ?
      OR cu.phone LIKE ?
      OR s.pickup_address LIKE ?
      OR s.delivery_address LIKE ?
      OR s.receiver_name LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search, search, search);
  }

  if (filters.status) {
    where.push('s.shipment_status = ?');
    values.push(filters.status);
  }

  if (filters.paymentStatus) {
    where.push('s.payment_status = ?');
    values.push(filters.paymentStatus);
  }

  if (filters.categoryId) {
    where.push('s.category_id = ?');
    values.push(filters.categoryId);
  }

  if (filters.customerId) {
    where.push('s.customer_id = ?');
    values.push(filters.customerId);
  }

  if (filters.assignedDriverId) {
    where.push(`EXISTS (
      SELECT 1
      FROM assignments a
      WHERE a.shipment_id = s.id
        AND a.driver_id = ?
        AND a.deleted_at IS NULL
    )`);
    values.push(filters.assignedDriverId);
  }

  if (filters.dateFrom) {
    where.push('DATE(s.created_at) >= DATE(?)');
    values.push(filters.dateFrom);
  }

  if (filters.dateTo) {
    where.push('DATE(s.created_at) <= DATE(?)');
    values.push(filters.dateTo);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const listShipments = async (
  { filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildFilters(filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM shipments s
      INNER JOIN customers c ON c.id = s.customer_id
      INNER JOIN users cu ON cu.id = c.user_id
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${shipmentColumns}
      FROM shipments s
      INNER JOIN customers c ON c.id = s.customer_id
      INNER JOIN users cu ON cu.id = c.user_id
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      WHERE ${whereSql}
      ORDER BY s.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapShipment),
    total: Number(firstRow(countRows).total || 0),
  };
};

const findById = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${shipmentColumns}
      FROM shipments s
      INNER JOIN customers c ON c.id = s.customer_id
      INNER JOIN users cu ON cu.id = c.user_id
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      WHERE s.id = ?
        AND s.deleted_at IS NULL
      LIMIT 1
    `,
    [shipmentId],
  );

  return mapShipment(firstRow(rows));
};

const findLatestPayment = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        id,
        payment_code AS paymentCode,
        payment_method AS paymentMethod,
        payment_status AS paymentStatus,
        currency,
        total_amount AS totalAmount,
        transaction_reference AS transactionReference,
        paid_at AS paidAt,
        created_at AS createdAt
      FROM payments
      WHERE shipment_id = ? AND deleted_at IS NULL
      ORDER BY created_at DESC
      LIMIT 1
    `,
    [shipmentId],
  );

  const payment = firstRow(rows);

  return payment
    ? {
        ...payment,
        totalAmount: Number(payment.totalAmount || 0),
      }
    : null;
};

const findLatestInvoice = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        id,
        invoice_number AS invoiceNumber,
        invoice_status AS invoiceStatus,
        payment_status AS paymentStatus,
        total_amount AS totalAmount,
        issued_at AS issuedAt,
        created_at AS createdAt
      FROM invoices
      WHERE shipment_id = ? AND deleted_at IS NULL
      ORDER BY created_at DESC
      LIMIT 1
    `,
    [shipmentId],
  );

  const invoice = firstRow(rows);

  return invoice
    ? {
        ...invoice,
        totalAmount: Number(invoice.totalAmount || 0),
      }
    : null;
};

const listAssignments = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${assignmentColumns}
      FROM assignments a
      INNER JOIN drivers d ON d.id = a.driver_id
      INNER JOIN users du ON du.id = d.user_id
      INNER JOIN vehicles v ON v.id = a.vehicle_id
      LEFT JOIN users au ON au.id = a.assigned_by_user_id
      WHERE a.shipment_id = ?
        AND a.deleted_at IS NULL
      ORDER BY a.assigned_at DESC, a.id DESC
    `,
    [shipmentId],
  );

  return rows.map(mapAssignment);
};

const listProofs = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        p.id,
        p.proof_code AS proofCode,
        p.proof_type AS proofType,
        p.file_url AS fileUrl,
        p.file_name AS fileName,
        p.notes,
        p.location_text AS locationText,
        p.verification_status AS verificationStatus,
        p.captured_at AS capturedAt,
        p.created_at AS createdAt,
        d.driver_code AS uploadedByDriverCode,
        du.name AS uploadedByDriverName
      FROM proof_uploads p
      LEFT JOIN drivers d ON d.id = p.uploaded_by_driver_id
      LEFT JOIN users du ON du.id = d.user_id
      WHERE p.shipment_id = ?
        AND p.deleted_at IS NULL
      ORDER BY p.created_at DESC
    `,
    [shipmentId],
  );

  return rows;
};

const listTripLogs = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        id,
        status,
        title,
        description,
        location_text AS locationText,
        event_time AS eventTime,
        created_at AS createdAt
      FROM trip_logs
      WHERE shipment_id = ?
        AND deleted_at IS NULL
      ORDER BY event_time ASC, id ASC
    `,
    [shipmentId],
  );

  return rows;
};

const approveShipment = async ({ shipmentId, actorUserId }, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE shipments
      SET shipment_status = 'approved',
          approved_by_user_id = ?,
          approved_at = CURRENT_TIMESTAMP,
          cancellation_reason = NULL
      WHERE id = ? AND deleted_at IS NULL
    `,
    [actorUserId, shipmentId],
  );

  return findById(shipmentId, connection);
};

const rejectShipment = async (
  { shipmentId, actorUserId, reason },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE shipments
      SET shipment_status = 'rejected',
          cancelled_by_user_id = ?,
          cancelled_at = CURRENT_TIMESTAMP,
          cancellation_reason = ?
      WHERE id = ? AND deleted_at IS NULL
    `,
    [actorUserId, reason, shipmentId],
  );

  return findById(shipmentId, connection);
};

const cancelShipment = async (
  { shipmentId, actorUserId, reason },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE shipments
      SET shipment_status = 'cancelled',
          cancelled_by_user_id = ?,
          cancelled_at = CURRENT_TIMESTAMP,
          cancellation_reason = ?
      WHERE id = ? AND deleted_at IS NULL
    `,
    [actorUserId, reason, shipmentId],
  );

  return findById(shipmentId, connection);
};

const setShipmentAssigned = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE shipments
      SET shipment_status = 'assigned'
      WHERE id = ? AND deleted_at IS NULL
    `,
    [shipmentId],
  );

  return findById(shipmentId, connection);
};

const listActiveAssignments = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        a.id,
        a.driver_id AS driverId,
        d.user_id AS driverUserId,
        a.vehicle_id AS vehicleId
      FROM assignments a
      INNER JOIN drivers d ON d.id = a.driver_id
      WHERE a.shipment_id = ?
        AND a.assignment_status IN (${ACTIVE_ASSIGNMENT_STATUSES.map(() => '?').join(', ')})
        AND a.deleted_at IS NULL
    `,
    [shipmentId, ...ACTIVE_ASSIGNMENT_STATUSES],
  );

  return rows;
};

const cancelAssignments = async ({ shipmentId, reason }, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE assignments
      SET assignment_status = 'cancelled',
          rejection_reason = ?
      WHERE shipment_id = ?
        AND assignment_status IN (${ACTIVE_ASSIGNMENT_STATUSES.map(() => '?').join(', ')})
        AND deleted_at IS NULL
    `,
    [reason, shipmentId, ...ACTIVE_ASSIGNMENT_STATUSES],
  );
};

const createAssignment = async (
  { shipmentId, driverId, vehicleId, actorUserId },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const now = new Date();
  const datePart = now.toISOString().slice(0, 10).replace(/-/g, '');
  const randomPart = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  const assignmentCode = `ASN-${datePart}-${Date.now().toString().slice(-6)}${randomPart}`;

  const [result] = await executor.execute(
    `
      INSERT INTO assignments (
        assignment_code, shipment_id, driver_id, vehicle_id,
        assigned_by_user_id, assignment_status
      )
      VALUES (?, ?, ?, ?, ?, 'assigned')
    `,
    [assignmentCode, shipmentId, driverId, vehicleId, actorUserId],
  );

  const assignments = await listAssignments(shipmentId, connection);
  return assignments.find((assignment) => Number(assignment.id) === Number(result.insertId));
};

const findAssignableDriver = async (
  { driverId, shipmentId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT d.id, d.driver_code AS driverCode, d.availability_status AS availabilityStatus
      FROM drivers d
      WHERE d.id = ?
        AND d.driver_status = 'active'
        AND d.availability_status IN ('available', 'busy')
        AND d.deleted_at IS NULL
        AND NOT EXISTS (
          SELECT 1
          FROM assignments a
          WHERE a.driver_id = d.id
            AND a.shipment_id <> ?
            AND a.assignment_status IN (${ACTIVE_ASSIGNMENT_STATUSES.map(() => '?').join(', ')})
            AND a.deleted_at IS NULL
        )
      LIMIT 1
    `,
    [driverId, shipmentId, ...ACTIVE_ASSIGNMENT_STATUSES],
  );

  return firstRow(rows);
};

const findAssignableVehicle = async (
  { vehicleId, driverId, shipmentId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT v.id, v.vehicle_number AS vehicleNumber, v.availability_status AS availabilityStatus
      FROM vehicles v
      WHERE v.id = ?
        AND v.availability_status IN ('available', 'assigned')
        AND (v.assigned_driver_id IS NULL OR v.assigned_driver_id = ?)
        AND v.deleted_at IS NULL
        AND NOT EXISTS (
          SELECT 1
          FROM assignments a
          WHERE a.vehicle_id = v.id
            AND a.shipment_id <> ?
            AND a.assignment_status IN (${ACTIVE_ASSIGNMENT_STATUSES.map(() => '?').join(', ')})
            AND a.deleted_at IS NULL
        )
      LIMIT 1
    `,
    [vehicleId, driverId, shipmentId, ...ACTIVE_ASSIGNMENT_STATUSES],
  );

  return firstRow(rows);
};

const countActiveDriverAssignments = async (
  { driverId, excludedShipmentId = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM assignments
      WHERE driver_id = ?
        AND (? IS NULL OR shipment_id <> ?)
        AND assignment_status IN (${ACTIVE_ASSIGNMENT_STATUSES.map(() => '?').join(', ')})
        AND deleted_at IS NULL
    `,
    [
      driverId,
      excludedShipmentId,
      excludedShipmentId,
      ...ACTIVE_ASSIGNMENT_STATUSES,
    ],
  );

  return Number(firstRow(rows).total || 0);
};

const countActiveVehicleAssignments = async (
  { vehicleId, excludedShipmentId = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM assignments
      WHERE vehicle_id = ?
        AND (? IS NULL OR shipment_id <> ?)
        AND assignment_status IN (${ACTIVE_ASSIGNMENT_STATUSES.map(() => '?').join(', ')})
        AND deleted_at IS NULL
    `,
    [
      vehicleId,
      excludedShipmentId,
      excludedShipmentId,
      ...ACTIVE_ASSIGNMENT_STATUSES,
    ],
  );

  return Number(firstRow(rows).total || 0);
};

const updateDriverAvailability = async (driverId, availabilityStatus, connection = null) => {
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

module.exports = {
  ACTIVE_ASSIGNMENT_STATUSES,
  approveShipment,
  cancelAssignments,
  cancelShipment,
  countActiveDriverAssignments,
  countActiveVehicleAssignments,
  createAssignment,
  findAssignableDriver,
  findAssignableVehicle,
  findById,
  findLatestInvoice,
  findLatestPayment,
  listActiveAssignments,
  listAssignments,
  listProofs,
  listShipments,
  listTripLogs,
  rejectShipment,
  setShipmentAssigned,
  updateDriverAvailability,
  updateVehicleAssignment,
};
