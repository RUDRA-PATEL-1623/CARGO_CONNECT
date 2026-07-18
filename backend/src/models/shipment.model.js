const { getPool } = require('../config/database');

const selectShipmentColumns = `
  s.id,
  s.shipment_code AS shipmentCode,
  s.customer_id AS customerId,
  s.category_id AS categoryId,
  s.pickup_address AS pickupAddress,
  s.pickup_city AS pickupCity,
  s.pickup_state AS pickupState,
  s.pickup_postal_code AS pickupPostalCode,
  s.delivery_address AS deliveryAddress,
  s.delivery_city AS deliveryCity,
  s.delivery_state AS deliveryState,
  s.delivery_postal_code AS deliveryPostalCode,
  s.receiver_name AS receiverName,
  s.receiver_phone AS receiverPhone,
  s.package_type AS packageType,
  s.package_weight_kg AS packageWeightKg,
  s.package_length_cm AS packageLengthCm,
  s.package_width_cm AS packageWidthCm,
  s.package_height_cm AS packageHeightCm,
  s.vehicle_preference AS vehiclePreference,
  s.is_fragile AS isFragile,
  s.delivery_notes AS deliveryNotes,
  s.scheduled_pickup_at AS pickupDateTime,
  s.estimated_distance_km AS estimatedDistanceKm,
  s.estimated_duration_minutes AS estimatedDurationMinutes,
  s.estimated_price AS estimatedPrice,
  s.shipment_status AS shipmentStatus,
  s.payment_status AS paymentStatus,
  s.created_at AS createdAt,
  s.updated_at AS updatedAt,
  c.code AS categoryCode,
  c.name AS categoryName,
  c.icon_key AS categoryIconKey,
  c.base_price AS categoryBasePrice,
  c.price_per_km AS categoryPricePerKm
`;

const getExecutor = (connection) => connection || getPool();

const mapShipment = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    packageWeightKg: Number(row.packageWeightKg),
    packageLengthCm:
      row.packageLengthCm === null ? null : Number(row.packageLengthCm),
    packageWidthCm:
      row.packageWidthCm === null ? null : Number(row.packageWidthCm),
    packageHeightCm:
      row.packageHeightCm === null ? null : Number(row.packageHeightCm),
    isFragile: Boolean(row.isFragile),
    estimatedDistanceKm:
      row.estimatedDistanceKm === null ? null : Number(row.estimatedDistanceKm),
    estimatedPrice: Number(row.estimatedPrice),
    categoryBasePrice:
      row.categoryBasePrice === null ? null : Number(row.categoryBasePrice),
    categoryPricePerKm:
      row.categoryPricePerKm === null ? null : Number(row.categoryPricePerKm),
  };
};

const createShipment = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO shipments (
        shipment_code, customer_id, category_id, pickup_address, pickup_city,
        pickup_state, pickup_postal_code, delivery_address, delivery_city,
        delivery_state, delivery_postal_code, receiver_name, receiver_phone,
        package_type, package_weight_kg, package_length_cm, package_width_cm,
        package_height_cm, vehicle_preference, is_fragile, delivery_notes,
        scheduled_pickup_at, estimated_distance_km, estimated_duration_minutes,
        estimated_price, shipment_status, payment_status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.shipmentCode,
      payload.customerId,
      payload.categoryId,
      payload.pickupAddress,
      payload.pickupCity || null,
      payload.pickupState || null,
      payload.pickupPostalCode || null,
      payload.deliveryAddress,
      payload.deliveryCity || null,
      payload.deliveryState || null,
      payload.deliveryPostalCode || null,
      payload.receiverName,
      payload.receiverPhone,
      payload.packageType,
      payload.packageWeightKg,
      payload.packageLengthCm || null,
      payload.packageWidthCm || null,
      payload.packageHeightCm || null,
      payload.vehiclePreference || null,
      payload.isFragile ? 1 : 0,
      payload.deliveryNotes || null,
      payload.pickupDateTime,
      payload.estimatedDistanceKm,
      payload.estimatedDurationMinutes,
      payload.estimatedPrice,
      payload.shipmentStatus || 'pending',
      payload.paymentStatus || 'unpaid',
    ],
  );

  return findByIdForCustomer({
    shipmentId: result.insertId,
    customerId: payload.customerId,
  }, connection);
};

const findByIdForCustomer = async (
  { shipmentId, customerId },
  connection = null,
) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectShipmentColumns}
      FROM shipments s
      INNER JOIN shipment_categories c ON c.id = s.category_id
      WHERE s.id = ?
        AND s.customer_id = ?
        AND s.deleted_at IS NULL
      LIMIT 1
    `,
    [shipmentId, customerId],
  );

  return mapShipment(rows[0]);
};

const updatePaymentStatus = async (
  { shipmentId, customerId, paymentStatus, shipmentStatus },
  connection = null,
) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE shipments
      SET payment_status = ?, shipment_status = ?
      WHERE id = ?
        AND customer_id = ?
        AND deleted_at IS NULL
    `,
    [paymentStatus, shipmentStatus, shipmentId, customerId],
  );

  return findByIdForCustomer({ shipmentId, customerId }, connection);
};

module.exports = {
  createShipment,
  findByIdForCustomer,
  updatePaymentStatus,
};
