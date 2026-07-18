const { getPool } = require('../config/database');

const selectInvoiceColumns = `
  i.id,
  i.invoice_number AS invoiceNumber,
  i.shipment_id AS shipmentId,
  i.payment_id AS paymentId,
  i.customer_id AS customerId,
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
  i.created_at AS createdAt
`;

const getExecutor = (connection) => connection || getPool();

const mapInvoice = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    subtotalAmount: Number(row.subtotalAmount),
    discountAmount: Number(row.discountAmount),
    taxAmount: Number(row.taxAmount),
    totalAmount: Number(row.totalAmount),
  };
};

const createInvoice = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO invoices (
        invoice_number, shipment_id, payment_id, customer_id, invoice_status,
        payment_status, billing_name, billing_email, billing_phone,
        billing_address, subtotal_amount, discount_amount, tax_amount,
        total_amount, due_at, pdf_url
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.invoiceNumber,
      payload.shipmentId,
      payload.paymentId || null,
      payload.customerId,
      payload.invoiceStatus || 'generated',
      payload.paymentStatus || 'paid',
      payload.billingName,
      payload.billingEmail || null,
      payload.billingPhone || null,
      payload.billingAddress || null,
      payload.subtotalAmount,
      payload.discountAmount || 0,
      payload.taxAmount,
      payload.totalAmount,
      payload.dueAt || null,
      payload.pdfUrl || null,
    ],
  );

  return findByIdForCustomer({
    invoiceId: result.insertId,
    customerId: payload.customerId,
  }, connection);
};

const findByIdForCustomer = async (
  { invoiceId, customerId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectInvoiceColumns}
      FROM invoices i
      WHERE i.id = ?
        AND i.customer_id = ?
        AND i.deleted_at IS NULL
      LIMIT 1
    `,
    [invoiceId, customerId],
  );

  return mapInvoice(rows[0]);
};

const findByShipmentIdForCustomer = async (
  { shipmentId, customerId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectInvoiceColumns}
      FROM invoices i
      WHERE i.shipment_id = ?
        AND i.customer_id = ?
        AND i.deleted_at IS NULL
      ORDER BY i.created_at DESC
      LIMIT 1
    `,
    [shipmentId, customerId],
  );

  return mapInvoice(rows[0]);
};

module.exports = {
  createInvoice,
  findByIdForCustomer,
  findByShipmentIdForCustomer,
};
