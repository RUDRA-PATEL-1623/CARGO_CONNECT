const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const supportIssueColumns = `
  si.id,
  si.issue_code AS issueCode,
  si.customer_id AS customerId,
  si.shipment_id AS shipmentId,
  s.shipment_code AS shipmentCode,
  si.issue_type AS issueType,
  si.priority,
  si.subject,
  si.description,
  si.attachment_url AS attachmentUrl,
  si.attachment_file_name AS attachmentFileName,
  si.attachment_mime_type AS attachmentMimeType,
  si.attachment_size_bytes AS attachmentSizeBytes,
  si.issue_status AS issueStatus,
  si.admin_response AS adminResponse,
  si.responded_by_user_id AS respondedByUserId,
  responder.name AS respondedByName,
  si.responded_at AS respondedAt,
  si.created_at AS createdAt,
  si.updated_at AS updatedAt
`;

const buildFilters = (customerId, filters = {}) => {
  const where = ['si.customer_id = ?', 'si.deleted_at IS NULL'];
  const values = [customerId];

  if (filters.status) {
    where.push('si.issue_status = ?');
    values.push(filters.status);
  }

  if (filters.priority) {
    where.push('si.priority = ?');
    values.push(filters.priority);
  }

  if (filters.issueType) {
    where.push('si.issue_type = ?');
    values.push(filters.issueType);
  }

  if (filters.shipmentId) {
    where.push('si.shipment_id = ?');
    values.push(filters.shipmentId);
  }

  if (filters.search) {
    where.push(`(
      si.issue_code LIKE ?
      OR si.subject LIKE ?
      OR si.description LIKE ?
      OR s.shipment_code LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const mapIssue = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    attachmentSizeBytes:
      row.attachmentSizeBytes === null || row.attachmentSizeBytes === undefined
        ? null
        : Number(row.attachmentSizeBytes),
  };
};

const createIssue = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO support_issues (
        issue_code, customer_id, shipment_id, issue_type, priority,
        subject, description, attachment_url, attachment_file_name,
        attachment_mime_type, attachment_size_bytes, issue_status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.issueCode,
      payload.customerId,
      payload.shipmentId || null,
      payload.issueType,
      payload.priority || 'medium',
      payload.subject,
      payload.description,
      payload.attachmentUrl || null,
      payload.attachmentFileName || null,
      payload.attachmentMimeType || null,
      payload.attachmentSizeBytes || null,
      payload.issueStatus || 'open',
    ],
  );

  return findByIdForCustomer(
    {
      customerId: payload.customerId,
      issueId: result.insertId,
    },
    connection,
  );
};

const listForCustomer = async (
  { customerId, filters = {}, pagination = {} },
  connection = null,
) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildFilters(customerId, filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      FROM support_issues si
      LEFT JOIN shipments s ON s.id = si.shipment_id
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${supportIssueColumns}
      FROM support_issues si
      LEFT JOIN shipments s ON s.id = si.shipment_id
      LEFT JOIN users responder ON responder.id = si.responded_by_user_id
      WHERE ${whereSql}
      ORDER BY si.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapIssue),
    total: Number(firstRow(countRows).total || 0),
  };
};

const findByIdForCustomer = async (
  { customerId, issueId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${supportIssueColumns}
      FROM support_issues si
      LEFT JOIN shipments s ON s.id = si.shipment_id
      LEFT JOIN users responder ON responder.id = si.responded_by_user_id
      WHERE si.customer_id = ?
        AND si.id = ?
        AND si.deleted_at IS NULL
      LIMIT 1
    `,
    [customerId, issueId],
  );

  return mapIssue(firstRow(rows));
};

module.exports = {
  createIssue,
  findByIdForCustomer,
  listForCustomer,
};
