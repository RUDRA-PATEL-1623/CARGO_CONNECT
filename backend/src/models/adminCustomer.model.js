const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => Number(value || 0);

const mapCustomer = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    totalShipments: toNumber(row.totalShipments),
    shipmentCount: toNumber(row.shipmentCount),
    activeShipments: toNumber(row.activeShipments),
    completedShipments: toNumber(row.completedShipments),
    cancelledShipments: toNumber(row.cancelledShipments),
    totalPaidAmount: Number(row.totalPaidAmount || 0),
  };
};

const customerColumns = `
  c.id,
  c.customer_code AS customerCode,
  c.user_id AS userId,
  u.public_id AS userPublicId,
  u.name,
  u.username,
  u.email,
  u.phone,
  u.avatar_url AS avatarUrl,
  u.status AS userStatus,
  u.email_verified_at AS emailVerifiedAt,
  u.phone_verified_at AS phoneVerifiedAt,
  u.last_login_at AS lastLoginAt,
  c.address_line1 AS addressLine1,
  c.address_line2 AS addressLine2,
  c.city,
  c.state,
  c.postal_code AS postalCode,
  c.country,
  c.account_status AS accountStatus,
  c.total_shipments AS totalShipments,
  c.notes,
  c.created_at AS registeredAt,
  c.updated_at AS updatedAt,
  (
    SELECT COUNT(*)
    FROM shipments s
    WHERE s.customer_id = c.id AND s.deleted_at IS NULL
  ) AS shipmentCount,
  (
    SELECT COUNT(*)
    FROM shipments s
    WHERE s.customer_id = c.id
      AND s.shipment_status IN ('approved', 'assigned', 'accepted', 'pickup_completed', 'in_transit')
      AND s.deleted_at IS NULL
  ) AS activeShipments,
  (
    SELECT COUNT(*)
    FROM shipments s
    WHERE s.customer_id = c.id
      AND s.shipment_status IN ('delivered', 'completed')
      AND s.deleted_at IS NULL
  ) AS completedShipments,
  (
    SELECT COUNT(*)
    FROM shipments s
    WHERE s.customer_id = c.id
      AND s.shipment_status = 'cancelled'
      AND s.deleted_at IS NULL
  ) AS cancelledShipments,
  (
    SELECT COALESCE(SUM(p.total_amount), 0)
    FROM payments p
    WHERE p.customer_id = c.id
      AND p.payment_status = 'paid'
      AND p.deleted_at IS NULL
  ) AS totalPaidAmount,
  (
    SELECT MAX(s.created_at)
    FROM shipments s
    WHERE s.customer_id = c.id AND s.deleted_at IS NULL
  ) AS lastShipmentAt
`;

const buildCustomerFilters = (filters = {}) => {
  const where = [
    'c.deleted_at IS NULL',
    'u.deleted_at IS NULL',
    "u.role = 'customer'",
  ];
  const values = [];

  if (filters.search) {
    where.push(`(
      c.customer_code LIKE ?
      OR u.name LIKE ?
      OR u.email LIKE ?
      OR u.phone LIKE ?
      OR c.city LIKE ?
      OR c.state LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search, search);
  }

  if (filters.accountStatus) {
    where.push('c.account_status = ?');
    values.push(filters.accountStatus);
  }

  if (filters.userStatus) {
    where.push('u.status = ?');
    values.push(filters.userStatus);
  }

  if (filters.city) {
    where.push('c.city = ?');
    values.push(filters.city);
  }

  if (filters.state) {
    where.push('c.state = ?');
    values.push(filters.state);
  }

  if (filters.dateFrom) {
    where.push('DATE(c.created_at) >= DATE(?)');
    values.push(filters.dateFrom);
  }

  if (filters.dateTo) {
    where.push('DATE(c.created_at) <= DATE(?)');
    values.push(filters.dateTo);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const listCustomers = async (
  { filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildCustomerFilters(filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM customers c
      INNER JOIN users u ON u.id = c.user_id
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${customerColumns}
      FROM customers c
      INNER JOIN users u ON u.id = c.user_id
      WHERE ${whereSql}
      ORDER BY c.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapCustomer),
    total: toNumber(firstRow(countRows).total),
  };
};

const findById = async (customerId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${customerColumns}
      FROM customers c
      INNER JOIN users u ON u.id = c.user_id
      WHERE c.id = ?
        AND c.deleted_at IS NULL
        AND u.deleted_at IS NULL
        AND u.role = 'customer'
      LIMIT 1
    `,
    [customerId],
  );

  return mapCustomer(firstRow(rows));
};

const listRecentShipments = async (
  { customerId, limit = 5 },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT
        s.id,
        s.shipment_code AS shipmentCode,
        sc.name AS categoryName,
        s.pickup_address AS pickupAddress,
        s.delivery_address AS deliveryAddress,
        s.shipment_status AS shipmentStatus,
        s.payment_status AS paymentStatus,
        s.estimated_price AS estimatedPrice,
        s.created_at AS createdAt
      FROM shipments s
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      WHERE s.customer_id = ?
        AND s.deleted_at IS NULL
      ORDER BY s.created_at DESC
      LIMIT ?
    `,
    [customerId, Number(limit)],
  );

  return rows.map((row) => ({
    ...row,
    estimatedPrice: Number(row.estimatedPrice || 0),
  }));
};

const updateStatus = async (
  { customerId, accountStatus, userStatus, notes = null },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE customers c
      INNER JOIN users u ON u.id = c.user_id
      SET c.account_status = ?,
          c.notes = CASE
            WHEN ? IS NULL THEN c.notes
            WHEN c.notes IS NULL OR c.notes = '' THEN ?
            ELSE CONCAT(c.notes, '\n', ?)
          END,
          u.status = ?
      WHERE c.id = ?
        AND c.deleted_at IS NULL
        AND u.deleted_at IS NULL
        AND u.role = 'customer'
    `,
    [accountStatus, notes, notes, notes, userStatus, customerId],
  );

  return findById(customerId, connection);
};

module.exports = {
  findById,
  listCustomers,
  listRecentShipments,
  updateStatus,
};
