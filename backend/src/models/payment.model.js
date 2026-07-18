const { getPool } = require('../config/database');

const selectPaymentColumns = `
  id,
  payment_code AS paymentCode,
  shipment_id AS shipmentId,
  customer_id AS customerId,
  payment_method AS paymentMethod,
  payment_status AS paymentStatus,
  currency,
  subtotal_amount AS subtotalAmount,
  discount_amount AS discountAmount,
  tax_amount AS taxAmount,
  fee_amount AS feeAmount,
  total_amount AS totalAmount,
  transaction_reference AS transactionReference,
  paid_at AS paidAt,
  created_at AS createdAt
`;

const getExecutor = (connection) => connection || getPool();

const mapPayment = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    subtotalAmount: Number(row.subtotalAmount),
    discountAmount: Number(row.discountAmount),
    taxAmount: Number(row.taxAmount),
    feeAmount: Number(row.feeAmount),
    totalAmount: Number(row.totalAmount),
  };
};

const createPayment = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO payments (
        payment_code, shipment_id, customer_id, payment_method,
        payment_status, currency, subtotal_amount, discount_amount,
        tax_amount, fee_amount, total_amount, transaction_reference, paid_at,
        metadata
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
    `,
    [
      payload.paymentCode,
      payload.shipmentId,
      payload.customerId,
      payload.paymentMethod,
      payload.paymentStatus || 'paid',
      payload.currency || 'INR',
      payload.subtotalAmount,
      payload.discountAmount || 0,
      payload.taxAmount,
      payload.feeAmount,
      payload.totalAmount,
      payload.transactionReference,
      payload.metadata ? JSON.stringify(payload.metadata) : null,
    ],
  );

  return findById(result.insertId, connection);
};

const findById = async (id, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectPaymentColumns}
      FROM payments
      WHERE id = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [id],
  );

  return mapPayment(rows[0]);
};

const findPaidByShipmentId = async (shipmentId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectPaymentColumns}
      FROM payments
      WHERE shipment_id = ?
        AND payment_status = 'paid'
        AND deleted_at IS NULL
      ORDER BY created_at DESC
      LIMIT 1
    `,
    [shipmentId],
  );

  return mapPayment(rows[0]);
};

module.exports = {
  createPayment,
  findById,
  findPaidByShipmentId,
};
