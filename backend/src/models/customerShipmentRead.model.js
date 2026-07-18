const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => (value === null || value === undefined ? null : Number(value));

const toBoolean = (value) => Boolean(value);

const mapShipment = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    pickupLatitude: toNumber(row.pickupLatitude),
    pickupLongitude: toNumber(row.pickupLongitude),
    deliveryLatitude: toNumber(row.deliveryLatitude),
    deliveryLongitude: toNumber(row.deliveryLongitude),
    packageWeightKg: toNumber(row.packageWeightKg),
    packageLengthCm: toNumber(row.packageLengthCm),
    packageWidthCm: toNumber(row.packageWidthCm),
    packageHeightCm: toNumber(row.packageHeightCm),
    estimatedDistanceKm: toNumber(row.estimatedDistanceKm),
    estimatedPrice: toNumber(row.estimatedPrice),
    isFragile: toBoolean(row.isFragile),
  };
};

const mapPayment = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    subtotalAmount: toNumber(row.subtotalAmount),
    discountAmount: toNumber(row.discountAmount),
    taxAmount: toNumber(row.taxAmount),
    feeAmount: toNumber(row.feeAmount),
    totalAmount: toNumber(row.totalAmount),
  };
};

const mapAssignment = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    driverRating: toNumber(row.driverRating),
    driverCompletedTrips: Number(row.driverCompletedTrips || 0),
    vehicleCapacityKg: toNumber(row.vehicleCapacityKg),
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

const shipmentColumns = `
  s.id,
  s.shipment_code AS shipmentCode,
  s.customer_id AS customerId,
  s.category_id AS categoryId,
  s.pickup_address AS pickupAddress,
  s.pickup_city AS pickupCity,
  s.pickup_state AS pickupState,
  s.pickup_postal_code AS pickupPostalCode,
  s.pickup_latitude AS pickupLatitude,
  s.pickup_longitude AS pickupLongitude,
  s.delivery_address AS deliveryAddress,
  s.delivery_city AS deliveryCity,
  s.delivery_state AS deliveryState,
  s.delivery_postal_code AS deliveryPostalCode,
  s.delivery_latitude AS deliveryLatitude,
  s.delivery_longitude AS deliveryLongitude,
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
  s.completed_at AS completedAt,
  s.created_at AS createdAt,
  s.updated_at AS updatedAt,
  c.code AS categoryCode,
  c.name AS categoryName,
  c.icon_key AS categoryIconKey,
  c.suggested_vehicle_type AS categoryVehicleSuggestion
`;

const buildShipmentFilters = (customerId, filters = {}) => {
  const where = ['s.customer_id = ?', 's.deleted_at IS NULL'];
  const values = [customerId];

  if (filters.search) {
    where.push(`(
      s.shipment_code LIKE ?
      OR s.pickup_address LIKE ?
      OR s.delivery_address LIKE ?
      OR s.receiver_name LIKE ?
      OR s.package_type LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search);
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

  if (filters.categoryCode) {
    where.push('c.code = ?');
    values.push(filters.categoryCode);
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

const listShipments = async (
  { customerId, filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildShipmentFilters(customerId, filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM shipments s
      INNER JOIN shipment_categories c ON c.id = s.category_id
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT
        ${shipmentColumns},
        (
          SELECT p.payment_code
          FROM payments p
          WHERE p.shipment_id = s.id AND p.deleted_at IS NULL
          ORDER BY p.created_at DESC
          LIMIT 1
        ) AS latestPaymentCode,
        (
          SELECT i.invoice_number
          FROM invoices i
          WHERE i.shipment_id = s.id AND i.deleted_at IS NULL
          ORDER BY i.created_at DESC
          LIMIT 1
        ) AS invoiceNumber
      FROM shipments s
      INNER JOIN shipment_categories c ON c.id = s.category_id
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

const findShipmentDetail = async (
  { customerId, shipmentId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${shipmentColumns}
      FROM shipments s
      INNER JOIN shipment_categories c ON c.id = s.category_id
      WHERE s.customer_id = ?
        AND s.id = ?
        AND s.deleted_at IS NULL
      LIMIT 1
    `,
    [customerId, shipmentId],
  );

  return mapShipment(firstRow(rows));
};

const findLatestPayment = async (
  { customerId, shipmentId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        id,
        payment_code AS paymentCode,
        shipment_id AS shipmentId,
        customer_id AS customerId,
        payment_method AS paymentMethod,
        payment_status AS paymentStatus,
        currency,
        subtotal_amount AS subtotalAmount,
        discount_amount AS discountAmount,
        tax_amount AS taxAmount,
        fee_amount AS feeAmount,
        total_amount AS totalAmount,
        transaction_reference AS transactionReference,
        paid_at AS paidAt,
        refunded_at AS refundedAt,
        failure_reason AS failureReason,
        created_at AS createdAt
      FROM payments
      WHERE customer_id = ?
        AND shipment_id = ?
        AND deleted_at IS NULL
      ORDER BY created_at DESC
      LIMIT 1
    `,
    [customerId, shipmentId],
  );

  return mapPayment(firstRow(rows));
};

const findLatestAssignment = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        a.id,
        a.assignment_code AS assignmentCode,
        a.shipment_id AS shipmentId,
        a.assignment_status AS assignmentStatus,
        a.assigned_at AS assignedAt,
        a.accepted_at AS acceptedAt,
        a.started_at AS startedAt,
        a.completed_at AS completedAt,
        d.id AS driverId,
        d.driver_code AS driverCode,
        d.rating AS driverRating,
        d.completed_trips AS driverCompletedTrips,
        du.name AS driverName,
        du.phone AS driverPhone,
        v.id AS vehicleId,
        v.vehicle_number AS vehicleNumber,
        v.registration_number AS vehicleRegistrationNumber,
        v.vehicle_type AS vehicleType,
        v.model AS vehicleModel,
        v.capacity_kg AS vehicleCapacityKg
      FROM assignments a
      LEFT JOIN drivers d ON d.id = a.driver_id AND d.deleted_at IS NULL
      LEFT JOIN users du ON du.id = d.user_id AND du.deleted_at IS NULL
      LEFT JOIN vehicles v ON v.id = a.vehicle_id AND v.deleted_at IS NULL
      WHERE a.shipment_id = ?
        AND a.deleted_at IS NULL
      ORDER BY a.assigned_at DESC
      LIMIT 1
    `,
    [shipmentId],
  );

  return mapAssignment(firstRow(rows));
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
  { shipmentId, proofType = null },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const values = [shipmentId];
  const proofFilter = proofType ? 'AND p.proof_type = ?' : '';

  if (proofType) {
    values.push(proofType);
  }

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
        p.created_at AS createdAt,
        d.driver_code AS driverCode,
        du.name AS uploadedByDriverName
      FROM proof_uploads p
      LEFT JOIN drivers d ON d.id = p.uploaded_by_driver_id AND d.deleted_at IS NULL
      LEFT JOIN users du ON du.id = d.user_id AND du.deleted_at IS NULL
      WHERE p.shipment_id = ?
        ${proofFilter}
        AND p.deleted_at IS NULL
      ORDER BY p.captured_at DESC, p.created_at DESC
    `,
    values,
  );

  return rows.map(mapProof);
};

const findProofById = async (
  { shipmentId, proofId },
  connection = null,
) => {
  const proofs = await listProofs({ shipmentId }, connection);
  return proofs.find((proof) => Number(proof.id) === Number(proofId)) || null;
};

module.exports = {
  findLatestAssignment,
  findLatestPayment,
  findProofById,
  findShipmentDetail,
  listProofs,
  listShipments,
  listTripLogs,
};
