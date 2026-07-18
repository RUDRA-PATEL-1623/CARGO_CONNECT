const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => (value === null || value === undefined ? null : Number(value));

const mapReport = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    latitude: toNumber(row.latitude),
    longitude: toNumber(row.longitude),
  };
};

const mapFuelRequest = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    fuelAmountLiters: toNumber(row.fuelAmountLiters),
    billAmount: toNumber(row.billAmount),
    billFileSizeBytes:
      row.billFileSizeBytes === null || row.billFileSizeBytes === undefined
        ? null
        : Number(row.billFileSizeBytes),
  };
};

const reportColumns = `
  er.id,
  er.report_code AS reportCode,
  er.driver_id AS driverId,
  d.driver_code AS driverCode,
  du.name AS driverName,
  du.phone AS driverPhone,
  er.vehicle_id AS vehicleId,
  v.vehicle_number AS vehicleNumber,
  v.registration_number AS vehicleRegistrationNumber,
  er.assignment_id AS assignmentId,
  a.assignment_code AS assignmentCode,
  er.shipment_id AS shipmentId,
  s.shipment_code AS shipmentCode,
  er.report_type AS reportType,
  er.issue_type AS issueType,
  er.severity,
  er.description,
  er.attachment_url AS attachmentUrl,
  er.location_text AS locationText,
  er.latitude,
  er.longitude,
  er.report_status AS reportStatus,
  er.resolved_by_user_id AS resolvedByUserId,
  ru.name AS resolvedByName,
  er.resolved_at AS resolvedAt,
  er.resolution_notes AS resolutionNotes,
  er.created_at AS createdAt,
  er.updated_at AS updatedAt
`;

const fuelColumns = `
  fr.id,
  fr.request_code AS requestCode,
  fr.driver_id AS driverId,
  d.driver_code AS driverCode,
  du.name AS driverName,
  du.phone AS driverPhone,
  fr.vehicle_id AS vehicleId,
  v.vehicle_number AS vehicleNumber,
  v.registration_number AS vehicleRegistrationNumber,
  fr.assignment_id AS assignmentId,
  a.assignment_code AS assignmentCode,
  s.id AS shipmentId,
  s.shipment_code AS shipmentCode,
  fr.fuel_amount_liters AS fuelAmountLiters,
  fr.bill_amount AS billAmount,
  fr.fuel_station AS fuelStation,
  fr.bill_file_url AS billFileUrl,
  fr.bill_file_name AS billFileName,
  fr.bill_file_mime_type AS billFileMimeType,
  fr.bill_file_size_bytes AS billFileSizeBytes,
  fr.notes,
  fr.request_status AS requestStatus,
  fr.reviewed_by_user_id AS reviewedByUserId,
  ru.name AS reviewedByName,
  fr.reviewed_at AS reviewedAt,
  fr.review_notes AS reviewNotes,
  fr.created_at AS createdAt,
  fr.updated_at AS updatedAt
`;

const createCode = (prefix) => {
  const now = new Date();
  const datePart = now.toISOString().slice(0, 10).replace(/-/g, '');
  const randomPart = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `${prefix}-${datePart}-${Date.now().toString().slice(-6)}${randomPart}`;
};

const findDriverAssignment = async (
  { driverId, assignmentId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        a.id AS assignmentId,
        a.assignment_code AS assignmentCode,
        a.driver_id AS driverId,
        a.vehicle_id AS vehicleId,
        a.shipment_id AS shipmentId,
        a.assignment_status AS assignmentStatus,
        s.shipment_code AS shipmentCode,
        s.shipment_status AS shipmentStatus
      FROM assignments a
      INNER JOIN shipments s ON s.id = a.shipment_id AND s.deleted_at IS NULL
      WHERE a.id = ?
        AND a.driver_id = ?
        AND a.deleted_at IS NULL
      LIMIT 1
    `,
    [assignmentId, driverId],
  );

  return firstRow(rows);
};

const findDriverVehicle = async (
  { driverId, vehicleId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        v.id,
        v.vehicle_number AS vehicleNumber,
        v.registration_number AS registrationNumber,
        v.vehicle_type AS vehicleType,
        v.availability_status AS availabilityStatus,
        v.assigned_driver_id AS assignedDriverId
      FROM vehicles v
      WHERE v.id = ?
        AND v.deleted_at IS NULL
        AND (
          v.assigned_driver_id = ?
          OR EXISTS (
            SELECT 1
            FROM assignments a
            WHERE a.vehicle_id = v.id
              AND a.driver_id = ?
              AND a.assignment_status IN (
                'assigned',
                'accepted',
                'started',
                'pickup_completed',
                'in_transit',
                'delivered'
              )
              AND a.deleted_at IS NULL
          )
        )
      LIMIT 1
    `,
    [vehicleId, driverId, driverId],
  );

  return firstRow(rows);
};

const findReportById = async (reportId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${reportColumns}
      FROM emergency_reports er
      INNER JOIN drivers d ON d.id = er.driver_id
      INNER JOIN users du ON du.id = d.user_id
      LEFT JOIN vehicles v ON v.id = er.vehicle_id
      LEFT JOIN assignments a ON a.id = er.assignment_id
      LEFT JOIN shipments s ON s.id = er.shipment_id
      LEFT JOIN users ru ON ru.id = er.resolved_by_user_id
      WHERE er.id = ?
        AND er.deleted_at IS NULL
      LIMIT 1
    `,
    [reportId],
  );

  return mapReport(firstRow(rows));
};

const createReport = async (
  {
    driverId,
    vehicleId,
    assignmentId,
    shipmentId,
    reportType,
    issueType,
    severity,
    description,
    attachmentUrl,
    locationText,
    latitude,
    longitude,
  },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const reportCode = createCode('RPT');

  const [result] = await executor.execute(
    `
      INSERT INTO emergency_reports (
        report_code, driver_id, vehicle_id, assignment_id, shipment_id,
        report_type, issue_type, severity, description, attachment_url,
        location_text, latitude, longitude, report_status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'open')
    `,
    [
      reportCode,
      driverId,
      vehicleId || null,
      assignmentId || null,
      shipmentId || null,
      reportType,
      issueType || null,
      severity,
      description,
      attachmentUrl || null,
      locationText || null,
      latitude ?? null,
      longitude ?? null,
    ],
  );

  return findReportById(result.insertId, connection);
};

const listDriverReports = async (
  { driverId, filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const where = ['er.driver_id = ?', 'er.deleted_at IS NULL'];
  const values = [driverId];

  if (filters.reportType) {
    where.push('er.report_type = ?');
    values.push(filters.reportType);
  }

  if (filters.status) {
    where.push('er.report_status = ?');
    values.push(filters.status);
  }

  const whereSql = where.join(' AND ');

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM emergency_reports er
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${reportColumns}
      FROM emergency_reports er
      INNER JOIN drivers d ON d.id = er.driver_id
      INNER JOIN users du ON du.id = d.user_id
      LEFT JOIN vehicles v ON v.id = er.vehicle_id
      LEFT JOIN assignments a ON a.id = er.assignment_id
      LEFT JOIN shipments s ON s.id = er.shipment_id
      LEFT JOIN users ru ON ru.id = er.resolved_by_user_id
      WHERE ${whereSql}
      ORDER BY er.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapReport),
    total: Number(firstRow(countRows).total || 0),
  };
};

const findFuelRequestById = async (fuelRequestId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${fuelColumns}
      FROM fuel_requests fr
      INNER JOIN drivers d ON d.id = fr.driver_id
      INNER JOIN users du ON du.id = d.user_id
      LEFT JOIN vehicles v ON v.id = fr.vehicle_id
      LEFT JOIN assignments a ON a.id = fr.assignment_id
      LEFT JOIN shipments s ON s.id = a.shipment_id
      LEFT JOIN users ru ON ru.id = fr.reviewed_by_user_id
      WHERE fr.id = ?
        AND fr.deleted_at IS NULL
      LIMIT 1
    `,
    [fuelRequestId],
  );

  return mapFuelRequest(firstRow(rows));
};

const createFuelRequest = async (
  {
    driverId,
    vehicleId,
    assignmentId,
    fuelAmountLiters,
    billAmount,
    fuelStation,
    notes,
  },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const requestCode = createCode('FUEL');

  const [result] = await executor.execute(
    `
      INSERT INTO fuel_requests (
        request_code, driver_id, vehicle_id, assignment_id,
        fuel_amount_liters, bill_amount, fuel_station, notes, request_status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    `,
    [
      requestCode,
      driverId,
      vehicleId || null,
      assignmentId || null,
      fuelAmountLiters,
      billAmount,
      fuelStation,
      notes || null,
    ],
  );

  return findFuelRequestById(result.insertId, connection);
};

const listDriverFuelRequests = async (
  { driverId, filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const where = ['fr.driver_id = ?', 'fr.deleted_at IS NULL'];
  const values = [driverId];

  if (filters.status) {
    where.push('fr.request_status = ?');
    values.push(filters.status);
  }

  const whereSql = where.join(' AND ');

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM fuel_requests fr
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${fuelColumns}
      FROM fuel_requests fr
      INNER JOIN drivers d ON d.id = fr.driver_id
      INNER JOIN users du ON du.id = d.user_id
      LEFT JOIN vehicles v ON v.id = fr.vehicle_id
      LEFT JOIN assignments a ON a.id = fr.assignment_id
      LEFT JOIN shipments s ON s.id = a.shipment_id
      LEFT JOIN users ru ON ru.id = fr.reviewed_by_user_id
      WHERE ${whereSql}
      ORDER BY fr.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapFuelRequest),
    total: Number(firstRow(countRows).total || 0),
  };
};

const updateFuelBill = async (
  {
    fuelRequestId,
    billFileUrl,
    billFileName,
    billFileMimeType,
    billFileSizeBytes,
    notes,
  },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE fuel_requests
      SET bill_file_url = ?,
          bill_file_name = ?,
          bill_file_mime_type = ?,
          bill_file_size_bytes = ?,
          notes = COALESCE(?, notes)
      WHERE id = ? AND deleted_at IS NULL
    `,
    [
      billFileUrl,
      billFileName || null,
      billFileMimeType || null,
      billFileSizeBytes || null,
      notes || null,
      fuelRequestId,
    ],
  );

  return findFuelRequestById(fuelRequestId, connection);
};

module.exports = {
  createFuelRequest,
  createReport,
  findDriverAssignment,
  findDriverVehicle,
  findFuelRequestById,
  findReportById,
  listDriverFuelRequests,
  listDriverReports,
  updateFuelBill,
};
