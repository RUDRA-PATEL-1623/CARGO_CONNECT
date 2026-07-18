const { getPool } = require('../config/database');
const { USER_STATUSES } = require('../constants/auth.constants');

const selectUserColumns = `
  id,
  public_id AS publicId,
  role,
  name,
  username,
  email,
  phone,
  avatar_url AS avatarUrl,
  status,
  email_verified_at AS emailVerifiedAt,
  phone_verified_at AS phoneVerifiedAt,
  last_login_at AS lastLoginAt,
  created_at AS createdAt,
  updated_at AS updatedAt,
  deleted_at AS deletedAt
`;

const selectUserColumnsWithPassword = `
  ${selectUserColumns},
  password_hash AS passwordHash
`;

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const createUser = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO users (
        public_id, role, name, username, email, phone, password_hash, status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.publicId,
      payload.role,
      payload.name,
      payload.username || null,
      payload.email || null,
      payload.phone || null,
      payload.passwordHash,
      payload.status || USER_STATUSES.ACTIVE,
    ],
  );

  return findById(result.insertId, { connection });
};

const findById = async (id, options = {}) => {
  const executor = getExecutor(options.connection);
  const columns = options.includePassword
    ? selectUserColumnsWithPassword
    : selectUserColumns;

  const [rows] = await executor.execute(
    `
      SELECT ${columns}
      FROM users
      WHERE id = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [id],
  );

  return firstRow(rows);
};

const findByPublicId = async (publicId, options = {}) => {
  const executor = getExecutor(options.connection);
  const columns = options.includePassword
    ? selectUserColumnsWithPassword
    : selectUserColumns;

  const [rows] = await executor.execute(
    `
      SELECT ${columns}
      FROM users
      WHERE public_id = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [publicId],
  );

  return firstRow(rows);
};

const findByIdentifier = async (identifier, options = {}) => {
  const executor = getExecutor(options.connection);
  const columns = options.includePassword
    ? selectUserColumnsWithPassword
    : selectUserColumns;

  const [rows] = await executor.execute(
    `
      SELECT ${columns}
      FROM users
      WHERE deleted_at IS NULL
        AND (email = ? OR phone = ? OR username = ?)
      LIMIT 1
    `,
    [identifier, identifier, identifier],
  );

  return firstRow(rows);
};

const findByEmail = async (email, options = {}) => {
  const executor = getExecutor(options.connection);
  const columns = options.includePassword
    ? selectUserColumnsWithPassword
    : selectUserColumns;

  const [rows] = await executor.execute(
    `
      SELECT ${columns}
      FROM users
      WHERE email = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [email],
  );

  return firstRow(rows);
};

const findByPhone = async (phone, options = {}) => {
  const executor = getExecutor(options.connection);
  const columns = options.includePassword
    ? selectUserColumnsWithPassword
    : selectUserColumns;

  const [rows] = await executor.execute(
    `
      SELECT ${columns}
      FROM users
      WHERE phone = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [phone],
  );

  return firstRow(rows);
};

const findByUsername = async (username, options = {}) => {
  const executor = getExecutor(options.connection);
  const columns = options.includePassword
    ? selectUserColumnsWithPassword
    : selectUserColumns;

  const [rows] = await executor.execute(
    `
      SELECT ${columns}
      FROM users
      WHERE username = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [username],
  );

  return firstRow(rows);
};

const updateLastLogin = async (id, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE users
      SET last_login_at = CURRENT_TIMESTAMP
      WHERE id = ? AND deleted_at IS NULL
    `,
    [id],
  );

  return findById(id, { connection });
};

const updatePassword = async (id, passwordHash, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE users
      SET password_hash = ?
      WHERE id = ? AND deleted_at IS NULL
    `,
    [passwordHash, id],
  );

  return findById(id, { connection });
};

const updateStatus = async (id, status, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE users
      SET status = ?
      WHERE id = ? AND deleted_at IS NULL
    `,
    [status, id],
  );

  return findById(id, { connection });
};

const updateProfile = async (id, payload, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE users
      SET
        name = ?,
        phone = ?,
        avatar_url = ?
      WHERE id = ? AND deleted_at IS NULL
    `,
    [
      payload.name,
      payload.phone || null,
      payload.avatarUrl || null,
      id,
    ],
  );

  return findById(id, { connection });
};

const markContactVerified = async (id, channel, connection = null) => {
  const executor = getExecutor(connection);
  const column =
    channel === 'phone' ? 'phone_verified_at' : 'email_verified_at';

  await executor.execute(
    `
      UPDATE users
      SET ${column} = CURRENT_TIMESTAMP
      WHERE id = ? AND deleted_at IS NULL
    `,
    [id],
  );

  return findById(id, { connection });
};

module.exports = {
  createUser,
  findByEmail,
  findById,
  findByIdentifier,
  findByPhone,
  findByPublicId,
  findByUsername,
  markContactVerified,
  updateLastLogin,
  updatePassword,
  updateProfile,
  updateStatus,
};
