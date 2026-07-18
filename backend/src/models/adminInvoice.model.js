const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => (
  value === null || value === undefined ? 0 : Number(value)
);

const invoiceColumns = `
  i.id,
  i.invoice_number AS invoiceNumber,
  i.shipment_id AS shipmentId,
  s.shipment_code AS shipmentCode,
  i.payment_id AS paymentId,
  p.payment_code AS paymentCode,
  p.payment_method AS paymentMethod,
  p.transaction_reference AS transactionReference,
  i.customer_id AS customerId,
  c.customer_code AS customerCode,
  cu.name AS customerName,
  cu.email AS customerEmail,
  cu.phone AS customerPhone,
  sc.id AS categoryId,
  sc.code AS categoryCode,
  sc.name AS categoryName,
  i.invoice_status AS invoiceStatus,
  i.payment_status AS paymentStatus,
  i.billing_name AS billingName,
  i.billing_email AS billingEmail,
  i.billing_phone AS billingPhone,
  i.billing_address AS billingAddress,
  i.subtotal_amount AS subtotalAmount,
  i.discount_amount AS discountAmount,
  i.tax_amount AS taxAmount,
  i.total_amount AS totalAmount,
  i.issued_at AS issuedAt,
  i.due_at AS dueAt,
  i.pdf_url AS pdfUrl,
  i.created_at AS createdAt,
  i.updated_at AS updatedAt,
  s.pickup_address AS pickupAddress,
  s.pickup_city AS pickupCity,
  s.pickup_state AS pickupState,
  s.pickup_postal_code AS pickupPostalCode,
  s.delivery_address AS deliveryAddress,
  s.delivery_city AS deliveryCity,
  s.delivery_state AS deliveryState,
  s.delivery_postal_code AS deliveryPostalCode,
  s.package_type AS packageType,
  s.package_weight_kg AS packageWeightKg,
  s.vehicle_preference AS vehiclePreference,
  s.receiver_name AS receiverName,
  s.receiver_phone AS receiverPhone,
  s.shipment_status AS shipmentStatus
`;

const invoiceJoins = `
  FROM invoices i
  INNER JOIN shipments s ON s.id = i.shipment_id AND s.deleted_at IS NULL
  INNER JOIN customers c ON c.id = i.customer_id AND c.deleted_at IS NULL
  INNER JOIN users cu ON cu.id = c.user_id AND cu.deleted_at IS NULL
  INNER JOIN shipment_categories sc ON sc.id = s.category_id AND sc.deleted_at IS NULL
  LEFT JOIN payments p ON p.id = i.payment_id AND p.deleted_at IS NULL
`;

const mapInvoice = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    packageWeightKg: toNumber(row.packageWeightKg),
    subtotalAmount: toNumber(row.subtotalAmount),
    discountAmount: toNumber(row.discountAmount),
    taxAmount: toNumber(row.taxAmount),
    totalAmount: toNumber(row.totalAmount),
  };
};

const buildFilters = (filters = {}) => {
  const where = ['i.deleted_at IS NULL'];
  const values = [];

  if (filters.search) {
    where.push(`(
      i.invoice_number LIKE ?
      OR s.shipment_code LIKE ?
      OR i.billing_name LIKE ?
      OR i.billing_email LIKE ?
      OR i.billing_phone LIKE ?
      OR p.payment_code LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search, search);
  }

  if (filters.invoiceStatus || filters.status) {
    where.push('i.invoice_status = ?');
    values.push(filters.invoiceStatus || filters.status);
  }

  if (filters.paymentStatus) {
    where.push('i.payment_status = ?');
    values.push(filters.paymentStatus);
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
    where.push('DATE(i.issued_at) >= DATE(?)');
    values.push(filters.dateFrom);
  }

  if (filters.dateTo) {
    where.push('DATE(i.issued_at) <= DATE(?)');
    values.push(filters.dateTo);
  }

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const listInvoices = async ({ filters = {}, pagination = {} }, connection = null) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildFilters(filters);

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(*) AS total
      ${invoiceJoins}
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT ${invoiceColumns}
      ${invoiceJoins}
      WHERE ${whereSql}
      ORDER BY i.issued_at DESC, i.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  return {
    rows: rows.map(mapInvoice),
    total: toNumber(firstRow(countRows)?.total),
  };
};

const findById = async (invoiceId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${invoiceColumns}
      ${invoiceJoins}
      WHERE i.id = ?
        AND i.deleted_at IS NULL
      LIMIT 1
    `,
    [invoiceId],
  );

  return mapInvoice(firstRow(rows));
};

module.exports = {
  findById,
  listInvoices,
};
