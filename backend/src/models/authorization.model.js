const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const customerMatchesUser = async (
  { userId, customerId = null, customerCode = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT id, customer_code AS customerCode
      FROM customers
      WHERE user_id = ?
        AND deleted_at IS NULL
        AND (? IS NULL OR id = ?)
        AND (? IS NULL OR customer_code = ?)
      LIMIT 1
    `,
    [
      userId,
      customerId || null,
      customerId || null,
      customerCode || null,
      customerCode || null,
    ],
  );

  return firstRow(rows);
};

const customerOwnsShipment = async (
  { userId, shipmentId = null, shipmentCode = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT s.id, s.shipment_code AS shipmentCode
      FROM shipments s
      INNER JOIN customers c ON c.id = s.customer_id
      WHERE c.user_id = ?
        AND c.deleted_at IS NULL
        AND s.deleted_at IS NULL
        AND (? IS NULL OR s.id = ?)
        AND (? IS NULL OR s.shipment_code = ?)
      LIMIT 1
    `,
    [
      userId,
      shipmentId || null,
      shipmentId || null,
      shipmentCode || null,
      shipmentCode || null,
    ],
  );

  return firstRow(rows);
};

const driverAssignedToShipment = async (
  { userId, shipmentId = null, shipmentCode = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT a.id, a.assignment_code AS assignmentCode, s.id AS shipmentId
      FROM assignments a
      INNER JOIN drivers d ON d.id = a.driver_id
      INNER JOIN shipments s ON s.id = a.shipment_id
      WHERE d.user_id = ?
        AND d.deleted_at IS NULL
        AND a.deleted_at IS NULL
        AND s.deleted_at IS NULL
        AND (? IS NULL OR s.id = ?)
        AND (? IS NULL OR s.shipment_code = ?)
      LIMIT 1
    `,
    [
      userId,
      shipmentId || null,
      shipmentId || null,
      shipmentCode || null,
      shipmentCode || null,
    ],
  );

  return firstRow(rows);
};

const driverOwnsAssignment = async (
  { userId, assignmentId = null, assignmentCode = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT a.id, a.assignment_code AS assignmentCode
      FROM assignments a
      INNER JOIN drivers d ON d.id = a.driver_id
      WHERE d.user_id = ?
        AND d.deleted_at IS NULL
        AND a.deleted_at IS NULL
        AND (? IS NULL OR a.id = ?)
        AND (? IS NULL OR a.assignment_code = ?)
      LIMIT 1
    `,
    [
      userId,
      assignmentId || null,
      assignmentId || null,
      assignmentCode || null,
      assignmentCode || null,
    ],
  );

  return firstRow(rows);
};

module.exports = {
  customerMatchesUser,
  customerOwnsShipment,
  driverAssignedToShipment,
  driverOwnsAssignment,
};
