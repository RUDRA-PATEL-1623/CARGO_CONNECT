const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const parseJson = (value) => {
  if (!value) {
    return [];
  }

  if (Array.isArray(value)) {
    return value;
  }

  try {
    return JSON.parse(value);
  } catch (error) {
    return [];
  }
};

const mapFeedback = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    rating: Number(row.rating),
    experienceTags: parseJson(row.experienceTags),
    wouldRecommend: Boolean(row.wouldRecommend),
  };
};

const feedbackColumns = `
  f.id,
  f.feedback_code AS feedbackCode,
  f.customer_id AS customerId,
  f.shipment_id AS shipmentId,
  s.shipment_code AS shipmentCode,
  f.rating,
  f.experience_tags AS experienceTags,
  f.comments,
  f.would_recommend AS wouldRecommend,
  f.created_at AS createdAt,
  f.updated_at AS updatedAt
`;

const createFeedback = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO feedback (
        feedback_code, customer_id, shipment_id, rating,
        experience_tags, comments, would_recommend
      )
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.feedbackCode,
      payload.customerId,
      payload.shipmentId,
      payload.rating,
      JSON.stringify(payload.experienceTags || []),
      payload.comments || null,
      payload.wouldRecommend ? 1 : 0,
    ],
  );

  return findByIdForCustomer(
    {
      customerId: payload.customerId,
      feedbackId: result.insertId,
    },
    connection,
  );
};

const findByShipmentForCustomer = async (
  { customerId, shipmentId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${feedbackColumns}
      FROM feedback f
      LEFT JOIN shipments s ON s.id = f.shipment_id
      WHERE f.customer_id = ?
        AND f.shipment_id = ?
        AND f.deleted_at IS NULL
      LIMIT 1
    `,
    [customerId, shipmentId],
  );

  return mapFeedback(firstRow(rows));
};

const findByIdForCustomer = async (
  { customerId, feedbackId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${feedbackColumns}
      FROM feedback f
      LEFT JOIN shipments s ON s.id = f.shipment_id
      WHERE f.customer_id = ?
        AND f.id = ?
        AND f.deleted_at IS NULL
      LIMIT 1
    `,
    [customerId, feedbackId],
  );

  return mapFeedback(firstRow(rows));
};

const listForCustomer = async (
  { customerId, filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const where = ['f.customer_id = ?', 'f.deleted_at IS NULL'];
  const values = [customerId];

  if (filters.shipmentId) {
    where.push('f.shipment_id = ?');
    values.push(filters.shipmentId);
  }

  if (filters.rating) {
    where.push('f.rating = ?');
    values.push(filters.rating);
  }

  const whereSql = where.join(' AND ');

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM feedback f
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${feedbackColumns}
      FROM feedback f
      LEFT JOIN shipments s ON s.id = f.shipment_id
      WHERE ${whereSql}
      ORDER BY f.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapFeedback),
    total: Number(firstRow(countRows).total || 0),
  };
};

module.exports = {
  createFeedback,
  findByIdForCustomer,
  findByShipmentForCustomer,
  listForCustomer,
};
