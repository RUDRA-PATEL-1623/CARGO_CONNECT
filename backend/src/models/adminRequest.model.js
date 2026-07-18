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
  du.email AS driverEmail,
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
  du.email AS driverEmail,
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

const buildReportFilters = (filters = {}) => {
  const where = ['er.deleted_at IS NULL'];
  const values = [];

  if (filters.search) {
    where.push(`(
      er.report_code LIKE ?
      OR du.name LIKE ?
      OR d.driver_code LIKE ?
      OR v.vehicle_number LIKE ?
      OR s.shipment_code LIKE ?
      OR er.description LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search, search);
  }

  if (filters.reportType) {
    where.push('er.report_type = ?');
    values.push(filters.reportType);
  }

  if (filters.status) {
    where.push('er.report_status = ?');
    values.push(filters.status);
  }

  if (filters.severity) {
    where.push('er.severity = ?');
    values.push(filters.severity);
  }

  if (filters.driverId) {
    where.push('er.driver_id = ?');
    values.push(filters.driverId);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const listReports = async (
  { filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildReportFilters(filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM emergency_reports er
      INNER JOIN drivers d ON d.id = er.driver_id
      INNER JOIN users du ON du.id = d.user_id
      LEFT JOIN vehicles v ON v.id = er.vehicle_id
      LEFT JOIN shipments s ON s.id = er.shipment_id
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
      ORDER BY
        CASE er.severity
          WHEN 'critical' THEN 0
          WHEN 'high' THEN 1
          WHEN 'medium' THEN 2
          ELSE 3
        END,
        er.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapReport),
    total: Number(firstRow(countRows).total || 0),
  };
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

const updateReportStatus = async (
  { reportId, reportStatus, actorUserId, resolutionNotes },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const isTerminal = ['resolved', 'closed'].includes(reportStatus);

  await executor.execute(
    `
      UPDATE emergency_reports
      SET report_status = ?,
          resolved_by_user_id = CASE WHEN ? THEN ? ELSE resolved_by_user_id END,
          resolved_at = CASE WHEN ? THEN CURRENT_TIMESTAMP ELSE resolved_at END,
          resolution_notes = COALESCE(?, resolution_notes)
      WHERE id = ? AND deleted_at IS NULL
    `,
    [
      reportStatus,
      isTerminal ? 1 : 0,
      actorUserId,
      isTerminal ? 1 : 0,
      resolutionNotes || null,
      reportId,
    ],
  );

  return findReportById(reportId, connection);
};

const buildFuelFilters = (filters = {}) => {
  const where = ['fr.deleted_at IS NULL'];
  const values = [];

  if (filters.search) {
    where.push(`(
      fr.request_code LIKE ?
      OR du.name LIKE ?
      OR d.driver_code LIKE ?
      OR v.vehicle_number LIKE ?
      OR fr.fuel_station LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search);
  }

  if (filters.status) {
    where.push('fr.request_status = ?');
    values.push(filters.status);
  }

  if (filters.driverId) {
    where.push('fr.driver_id = ?');
    values.push(filters.driverId);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const listFuelRequests = async (
  { filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildFuelFilters(filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM fuel_requests fr
      INNER JOIN drivers d ON d.id = fr.driver_id
      INNER JOIN users du ON du.id = d.user_id
      LEFT JOIN vehicles v ON v.id = fr.vehicle_id
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

const updateFuelStatus = async (
  { fuelRequestId, requestStatus, actorUserId, reviewNotes },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE fuel_requests
      SET request_status = ?,
          reviewed_by_user_id = ?,
          reviewed_at = CURRENT_TIMESTAMP,
          review_notes = COALESCE(?, review_notes)
      WHERE id = ? AND deleted_at IS NULL
    `,
    [requestStatus, actorUserId, reviewNotes || null, fuelRequestId],
  );

  return findFuelRequestById(fuelRequestId, connection);
};

module.exports = {
  findFuelRequestById,
  findReportById,
  listFuelRequests,
  listReports,
  updateFuelStatus,
  updateReportStatus,
};
