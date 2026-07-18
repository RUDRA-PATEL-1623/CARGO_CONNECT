const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => Number(value || 0);

const buildDateFilter = (alias, filters = {}, column = 'created_at') => {
  const clauses = [`${alias}.deleted_at IS NULL`];
  const values = [];

  if (filters.dateFrom) {
    clauses.push(`DATE(${alias}.${column}) >= DATE(?)`);
    values.push(filters.dateFrom);
  }

  if (filters.dateTo) {
    clauses.push(`DATE(${alias}.${column}) <= DATE(?)`);
    values.push(filters.dateTo);
  }

  return {
    sql: clauses.join(' AND '),
    values,
  };
};

const getShipmentMetrics = async (filters = {}, connection = null) => {
  const executor = getExecutor(connection);
  const dateFilter = buildDateFilter('s', filters);

  const [rows] = await executor.execute(
    `
      SELECT
        COUNT(*) AS totalShipments,
        SUM(CASE WHEN s.shipment_status = 'pending' THEN 1 ELSE 0 END) AS pendingShipments,
        SUM(CASE WHEN s.shipment_status IN (
          'approved',
          'assigned',
          'accepted',
          'pickup_completed',
          'in_transit'
        ) THEN 1 ELSE 0 END) AS activeDeliveries,
        SUM(CASE WHEN s.shipment_status IN ('delivered', 'completed') THEN 1 ELSE 0 END) AS deliveredShipments,
        SUM(CASE WHEN s.shipment_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelledShipments
      FROM shipments s
      WHERE ${dateFilter.sql}
    `,
    dateFilter.values,
  );

  const metrics = firstRow(rows) || {};

  return {
    totalShipments: toNumber(metrics.totalShipments),
    pendingShipments: toNumber(metrics.pendingShipments),
    activeDeliveries: toNumber(metrics.activeDeliveries),
    deliveredShipments: toNumber(metrics.deliveredShipments),
    cancelledShipments: toNumber(metrics.cancelledShipments),
  };
};

const getDriverMetrics = async (connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        COUNT(*) AS totalDrivers,
        SUM(CASE WHEN driver_status = 'active' THEN 1 ELSE 0 END) AS activeDrivers,
        SUM(CASE WHEN driver_status = 'active' AND availability_status = 'available' THEN 1 ELSE 0 END) AS availableDrivers,
        SUM(CASE WHEN driver_status = 'active' AND availability_status = 'busy' THEN 1 ELSE 0 END) AS busyDrivers,
        SUM(CASE WHEN driver_status = 'active' AND availability_status = 'offline' THEN 1 ELSE 0 END) AS offlineDrivers
      FROM drivers
      WHERE deleted_at IS NULL
    `,
  );

  const metrics = firstRow(rows) || {};

  return {
    totalDrivers: toNumber(metrics.totalDrivers),
    activeDrivers: toNumber(metrics.activeDrivers),
    availableDrivers: toNumber(metrics.availableDrivers),
    busyDrivers: toNumber(metrics.busyDrivers),
    offlineDrivers: toNumber(metrics.offlineDrivers),
  };
};

const getVehicleUtilization = async (connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        COUNT(*) AS totalVehicles,
        SUM(CASE WHEN availability_status = 'available' THEN 1 ELSE 0 END) AS availableVehicles,
        SUM(CASE WHEN availability_status = 'assigned' THEN 1 ELSE 0 END) AS assignedVehicles,
        SUM(CASE WHEN availability_status = 'maintenance' THEN 1 ELSE 0 END) AS maintenanceVehicles,
        SUM(CASE WHEN availability_status = 'inactive' THEN 1 ELSE 0 END) AS inactiveVehicles
      FROM vehicles
      WHERE deleted_at IS NULL
    `,
  );

  const metrics = firstRow(rows) || {};
  const totalVehicles = toNumber(metrics.totalVehicles);
  const assignedVehicles = toNumber(metrics.assignedVehicles);
  const utilizationPercent = totalVehicles
    ? Number(((assignedVehicles / totalVehicles) * 100).toFixed(2))
    : 0;

  return {
    totalVehicles,
    availableVehicles: toNumber(metrics.availableVehicles),
    assignedVehicles,
    maintenanceVehicles: toNumber(metrics.maintenanceVehicles),
    inactiveVehicles: toNumber(metrics.inactiveVehicles),
    utilizationPercent,
  };
};

const getRevenueSummary = async (filters = {}, connection = null) => {
  const executor = getExecutor(connection);
  const dateFilter = buildDateFilter('p', filters);

  const [rows] = await executor.execute(
    `
      SELECT
        COUNT(*) AS totalPayments,
        SUM(CASE WHEN p.payment_status = 'paid' THEN 1 ELSE 0 END) AS paidPayments,
        SUM(CASE WHEN p.payment_status = 'pending' THEN 1 ELSE 0 END) AS pendingPayments,
        SUM(CASE WHEN p.payment_status = 'refunded' THEN 1 ELSE 0 END) AS refundedPayments,
        COALESCE(SUM(CASE WHEN p.payment_status = 'paid' THEN p.total_amount ELSE 0 END), 0) AS paidAmount,
        COALESCE(SUM(CASE WHEN p.payment_status = 'pending' THEN p.total_amount ELSE 0 END), 0) AS pendingAmount,
        COALESCE(SUM(CASE WHEN p.payment_status = 'refunded' THEN p.total_amount ELSE 0 END), 0) AS refundedAmount
      FROM payments p
      WHERE ${dateFilter.sql}
    `,
    dateFilter.values,
  );

  const [methodRows] = await executor.execute(
    `
      SELECT
        p.payment_method AS paymentMethod,
        COUNT(*) AS paymentCount,
        COALESCE(SUM(CASE WHEN p.payment_status = 'paid' THEN p.total_amount ELSE 0 END), 0) AS paidAmount
      FROM payments p
      WHERE ${dateFilter.sql}
      GROUP BY p.payment_method
      ORDER BY paidAmount DESC, paymentCount DESC
    `,
    dateFilter.values,
  );

  const metrics = firstRow(rows) || {};
  const paidPayments = toNumber(metrics.paidPayments);
  const paidAmount = toNumber(metrics.paidAmount);

  return {
    currency: 'INR',
    totalPayments: toNumber(metrics.totalPayments),
    paidPayments,
    pendingPayments: toNumber(metrics.pendingPayments),
    refundedPayments: toNumber(metrics.refundedPayments),
    paidAmount,
    pendingAmount: toNumber(metrics.pendingAmount),
    refundedAmount: toNumber(metrics.refundedAmount),
    averageOrderValue: paidPayments
      ? Number((paidAmount / paidPayments).toFixed(2))
      : 0,
    methodBreakdown: methodRows.map((row) => ({
      paymentMethod: row.paymentMethod,
      paymentCount: toNumber(row.paymentCount),
      paidAmount: toNumber(row.paidAmount),
    })),
  };
};

const getRecentActivity = async ({ limit = 10 } = {}, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT *
      FROM (
        SELECT
          'shipment_created' AS activityType,
          s.id AS resourceId,
          s.shipment_code AS resourceCode,
          CONCAT('Shipment ', s.shipment_code, ' created') AS title,
          cu.name AS actorName,
          s.shipment_status AS status,
          s.created_at AS occurredAt
        FROM shipments s
        LEFT JOIN customers c ON c.id = s.customer_id
        LEFT JOIN users cu ON cu.id = c.user_id
        WHERE s.deleted_at IS NULL

        UNION ALL

        SELECT
          'payment_recorded' AS activityType,
          p.id AS resourceId,
          p.payment_code AS resourceCode,
          CONCAT('Payment ', p.payment_status, ' for ', s.shipment_code) AS title,
          cu.name AS actorName,
          p.payment_status AS status,
          p.created_at AS occurredAt
        FROM payments p
        INNER JOIN shipments s ON s.id = p.shipment_id
        LEFT JOIN customers c ON c.id = p.customer_id
        LEFT JOIN users cu ON cu.id = c.user_id
        WHERE p.deleted_at IS NULL
          AND s.deleted_at IS NULL

        UNION ALL

        SELECT
          'driver_assigned' AS activityType,
          a.id AS resourceId,
          a.assignment_code AS resourceCode,
          CONCAT('Driver assigned to ', s.shipment_code) AS title,
          au.name AS actorName,
          a.assignment_status AS status,
          a.assigned_at AS occurredAt
        FROM assignments a
        INNER JOIN shipments s ON s.id = a.shipment_id
        LEFT JOIN users au ON au.id = a.assigned_by_user_id
        WHERE a.deleted_at IS NULL
          AND s.deleted_at IS NULL

        UNION ALL

        SELECT
          'proof_uploaded' AS activityType,
          p.id AS resourceId,
          p.proof_code AS resourceCode,
          CONCAT(UPPER(SUBSTRING(p.proof_type, 1, 1)), SUBSTRING(p.proof_type, 2), ' proof uploaded') AS title,
          du.name AS actorName,
          p.verification_status AS status,
          p.created_at AS occurredAt
        FROM proof_uploads p
        LEFT JOIN drivers d ON d.id = p.uploaded_by_driver_id
        LEFT JOIN users du ON du.id = d.user_id
        WHERE p.deleted_at IS NULL
      ) recent_activity
      ORDER BY occurredAt DESC
      LIMIT ?
    `,
    [Number(limit)],
  );

  return rows.map((row) => ({
    ...row,
    actorName: row.actorName || 'System',
  }));
};

module.exports = {
  getDriverMetrics,
  getRecentActivity,
  getRevenueSummary,
  getShipmentMetrics,
  getVehicleUtilization,
};
