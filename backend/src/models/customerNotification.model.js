const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const parseMetadata = (metadata) => {
  if (!metadata) {
    return null;
  }

  if (typeof metadata === 'object') {
    return metadata;
  }

  try {
    return JSON.parse(metadata);
  } catch (error) {
    return null;
  }
};

const mapNotification = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    isRead: Boolean(row.readAt),
    metadata: parseMetadata(row.metadata),
  };
};

const notificationColumns = `
  n.id,
  n.user_id AS userId,
  n.shipment_id AS shipmentId,
  s.shipment_code AS shipmentCode,
  n.notification_type AS notificationType,
  n.title,
  n.message,
  n.channel,
  n.read_at AS readAt,
  n.sent_at AS sentAt,
  n.metadata,
  n.created_at AS createdAt
`;

const buildFilters = (userId, filters = {}) => {
  const where = ['n.user_id = ?', 'n.deleted_at IS NULL'];
  const values = [userId];

  if (filters.notificationType) {
    where.push('n.notification_type = ?');
    values.push(filters.notificationType);
  }

  if (filters.unreadOnly) {
    where.push('n.read_at IS NULL');
  }

  if (filters.shipmentId) {
    where.push('n.shipment_id = ?');
    values.push(filters.shipmentId);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const listForUser = async (
  { userId, filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 20);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildFilters(userId, filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM notifications n
      LEFT JOIN shipments s ON s.id = n.shipment_id
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${notificationColumns}
      FROM notifications n
      LEFT JOIN shipments s ON s.id = n.shipment_id
      WHERE ${whereSql}
      ORDER BY n.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapNotification),
    total: Number(firstRow(countRows).total || 0),
  };
};

const countUnreadForUser = async (userId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT COUNT(*) AS unreadCount
      FROM notifications
      WHERE user_id = ?
        AND read_at IS NULL
        AND deleted_at IS NULL
    `,
    [userId],
  );

  return Number(firstRow(rows).unreadCount || 0);
};

const findForUser = async ({ userId, notificationId }, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${notificationColumns}
      FROM notifications n
      LEFT JOIN shipments s ON s.id = n.shipment_id
      WHERE n.user_id = ?
        AND n.id = ?
        AND n.deleted_at IS NULL
      LIMIT 1
    `,
    [userId, notificationId],
  );

  return mapNotification(firstRow(rows));
};

const markAsRead = async ({ userId, notificationId }, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE notifications
      SET read_at = COALESCE(read_at, CURRENT_TIMESTAMP)
      WHERE user_id = ?
        AND id = ?
        AND deleted_at IS NULL
    `,
    [userId, notificationId],
  );

  return findForUser({ userId, notificationId }, connection);
};

const markAllAsRead = async (userId, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      UPDATE notifications
      SET read_at = COALESCE(read_at, CURRENT_TIMESTAMP)
      WHERE user_id = ?
        AND read_at IS NULL
        AND deleted_at IS NULL
    `,
    [userId],
  );

  return result.affectedRows;
};

const clearAllForUser = async (userId, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      UPDATE notifications
      SET deleted_at = CURRENT_TIMESTAMP
      WHERE user_id = ?
        AND deleted_at IS NULL
    `,
    [userId],
  );

  return result.affectedRows;
};

module.exports = {
  clearAllForUser,
  countUnreadForUser,
  findForUser,
  listForUser,
  markAllAsRead,
  markAsRead,
};
