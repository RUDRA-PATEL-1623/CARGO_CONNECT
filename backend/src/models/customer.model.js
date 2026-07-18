const { getPool } = require('../config/database');

const selectCustomerColumns = `
  id,
  user_id AS userId,
  customer_code AS customerCode,
  address_line1 AS addressLine1,
  address_line2 AS addressLine2,
  city,
  state,
  postal_code AS postalCode,
  country,
  account_status AS accountStatus,
  total_shipments AS totalShipments,
  notes,
  created_at AS createdAt,
  updated_at AS updatedAt,
  deleted_at AS deletedAt
`;

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const createCustomer = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO customers (
        user_id, customer_code, address_line1, address_line2, city,
        state, postal_code, country, account_status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.userId,
      payload.customerCode,
      payload.addressLine1 || null,
      payload.addressLine2 || null,
      payload.city || null,
      payload.state || null,
      payload.postalCode || null,
      payload.country || 'India',
      payload.accountStatus || 'inactive',
    ],
  );

  return findById(result.insertId, connection);
};

const findById = async (id, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectCustomerColumns}
      FROM customers
      WHERE id = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [id],
  );

  return firstRow(rows);
};

const findByUserId = async (userId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectCustomerColumns}
      FROM customers
      WHERE user_id = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [userId],
  );

  return firstRow(rows);
};

const updateAccountStatusByUserId = async (userId, accountStatus, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE customers
      SET account_status = ?
      WHERE user_id = ? AND deleted_at IS NULL
    `,
    [accountStatus, userId],
  );

  return findByUserId(userId, connection);
};

const updateProfileByUserId = async (userId, payload, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE customers
      SET
        address_line1 = ?,
        address_line2 = ?,
        city = ?,
        state = ?,
        postal_code = ?,
        country = ?
      WHERE user_id = ? AND deleted_at IS NULL
    `,
    [
      payload.addressLine1 || null,
      payload.addressLine2 || null,
      payload.city || null,
      payload.state || null,
      payload.postalCode || null,
      payload.country || 'India',
      userId,
    ],
  );

  return findByUserId(userId, connection);
};

const incrementTotalShipments = async (customerId, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE customers
      SET total_shipments = total_shipments + 1
      WHERE id = ? AND deleted_at IS NULL
    `,
    [customerId],
  );

  return findById(customerId, connection);
};

module.exports = {
  createCustomer,
  findById,
  findByUserId,
  incrementTotalShipments,
  updateAccountStatusByUserId,
  updateProfileByUserId,
};
