const { getPool } = require('../config/database');

const selectOtpColumns = `
  id,
  user_id AS userId,
  destination,
  purpose,
  otp_hash AS otpHash,
  attempts,
  max_attempts AS maxAttempts,
  expires_at AS expiresAt,
  consumed_at AS consumedAt,
  metadata,
  created_at AS createdAt,
  updated_at AS updatedAt
`;

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const createOtp = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO auth_otps (
        user_id, destination, purpose, otp_hash, max_attempts, expires_at, metadata
      )
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.userId || null,
      payload.destination,
      payload.purpose,
      payload.otpHash,
      payload.maxAttempts || 5,
      payload.expiresAt,
      payload.metadata ? JSON.stringify(payload.metadata) : null,
    ],
  );

  return findById(result.insertId, connection);
};

const findById = async (id, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectOtpColumns}
      FROM auth_otps
      WHERE id = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [id],
  );

  return firstRow(rows);
};

const findLatestActive = async ({ userId, destination, purpose }, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectOtpColumns}
      FROM auth_otps
      WHERE purpose = ?
        AND destination = ?
        AND (? IS NULL OR user_id = ?)
        AND consumed_at IS NULL
        AND deleted_at IS NULL
        AND expires_at > UTC_TIMESTAMP()
      ORDER BY created_at DESC
      LIMIT 1
    `,
    [purpose, destination, userId || null, userId || null],
  );

  return firstRow(rows);
};

const incrementAttempts = async (id, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE auth_otps
      SET attempts = attempts + 1
      WHERE id = ? AND deleted_at IS NULL
    `,
    [id],
  );

  return findById(id, connection);
};

const markConsumed = async (id, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE auth_otps
      SET consumed_at = CURRENT_TIMESTAMP
      WHERE id = ? AND deleted_at IS NULL
    `,
    [id],
  );

  return findById(id, connection);
};

const consumeActiveOtps = async (
  { userId, destination, purpose },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE auth_otps
      SET consumed_at = CURRENT_TIMESTAMP
      WHERE purpose = ?
        AND destination = ?
        AND (? IS NULL OR user_id = ?)
        AND consumed_at IS NULL
        AND deleted_at IS NULL
    `,
    [purpose, destination, userId || null, userId || null],
  );
};

module.exports = {
  consumeActiveOtps,
  createOtp,
  findById,
  findLatestActive,
  incrementAttempts,
  markConsumed,
};
