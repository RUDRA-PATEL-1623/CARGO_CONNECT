const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => (
  value === null || value === undefined ? 0 : Number(value)
);

const paymentColumns = `
  p.id,
  p.payment_code AS paymentCode,
  p.shipment_id AS shipmentId,
  s.shipment_code AS shipmentCode,
  p.customer_id AS customerId,
  c.customer_code AS customerCode,
  cu.name AS customerName,
  cu.email AS customerEmail,
  cu.phone AS customerPhone,
  sc.id AS categoryId,
  sc.code AS categoryCode,
  sc.name AS categoryName,
  p.payment_method AS paymentMethod,
  p.payment_status AS paymentStatus,
  p.currency,
  p.subtotal_amount AS subtotalAmount,
  p.discount_amount AS discountAmount,
  p.tax_amount AS taxAmount,
  p.fee_amount AS feeAmount,
  p.total_amount AS totalAmount,
  p.transaction_reference AS transactionReference,
  p.paid_at AS paidAt,
  p.refunded_at AS refundedAt,
  p.failure_reason AS failureReason,
  p.metadata,
  p.created_at AS createdAt,
  p.updated_at AS updatedAt,
  i.id AS invoiceId,
  i.invoice_number AS invoiceNumber,
  i.invoice_status AS invoiceStatus,
  s.shipment_status AS shipmentStatus,
  s.payment_status AS shipmentPaymentStatus
`;

const paymentJoins = `
  FROM payments p
  INNER JOIN shipments s ON s.id = p.shipment_id AND s.deleted_at IS NULL
  INNER JOIN customers c ON c.id = p.customer_id AND c.deleted_at IS NULL
  INNER JOIN users cu ON cu.id = c.user_id AND cu.deleted_at IS NULL
  INNER JOIN shipment_categories sc ON sc.id = s.category_id AND sc.deleted_at IS NULL
  LEFT JOIN invoices i ON i.payment_id = p.id AND i.deleted_at IS NULL
`;

const mapPayment = (row) => {
  if (!row) {
    return null;
  }

  let metadata = row.metadata;
  if (typeof metadata === 'string') {
    try {
      metadata = JSON.parse(metadata || '{}');
    } catch (error) {
      metadata = {};
    }
  }

  return {
    ...row,
    subtotalAmount: toNumber(row.subtotalAmount),
    discountAmount: toNumber(row.discountAmount),
    taxAmount: toNumber(row.taxAmount),
    feeAmount: toNumber(row.feeAmount),
    totalAmount: toNumber(row.totalAmount),
    metadata,
  };
};

const buildFilters = (filters = {}) => {
  const where = ['p.deleted_at IS NULL'];
  const values = [];

  if (filters.search) {
    where.push(`(
      p.payment_code LIKE ?
      OR p.transaction_reference LIKE ?
      OR s.shipment_code LIKE ?
      OR cu.name LIKE ?
      OR cu.email LIKE ?
      OR cu.phone LIKE ?
      OR i.invoice_number LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search, search, search);
  }

  if (filters.paymentStatus || filters.status) {
    where.push('p.payment_status = ?');
    values.push(filters.paymentStatus || filters.status);
  }

  if (filters.paymentMethod) {
    where.push('p.payment_method = ?');
    values.push(filters.paymentMethod);
  }

  if (filters.categoryId) {
    where.push('sc.id = ?');
    values.push(filters.categoryId);
  }

  if (filters.categoryCode) {
    where.push('sc.code = ?');
    values.push(filters.categoryCode);
  }

  if (filters.dateFrom) {
    where.push('DATE(p.created_at) >= DATE(?)');
    values.push(filters.dateFrom);
  }

  if (filters.dateTo) {
    where.push('DATE(p.created_at) <= DATE(?)');
    values.push(filters.dateTo);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const listPayments = async ({ filters = {}, pagination = {} }, connection = null) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildFilters(filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(DISTINCT p.id) AS total
      ${paymentJoins}
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${paymentColumns}
      ${paymentJoins}
      WHERE ${whereSql}
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapPayment),
    total: toNumber(firstRow(countRows)?.total),
  };
};

const findById = async (paymentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${paymentColumns}
      ${paymentJoins}
      WHERE p.id = ?
        AND p.deleted_at IS NULL
      LIMIT 1
    `,
    [paymentId],
  );

  return mapPayment(firstRow(rows));
};

module.exports = {
  findById,
  listPayments,
};
