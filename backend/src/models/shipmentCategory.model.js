const { getPool } = require('../config/database');

const selectCategoryColumns = `
  id,
  code,
  name,
  description,
  suggested_vehicle_type AS vehicleSuggestion,
  icon_key AS iconKey,
  base_price AS basePrice,
  price_per_km AS pricePerKm,
  max_weight_kg AS maxWeightKg,
  is_fragile_allowed AS isFragileAllowed,
  is_active AS isActive,
  sort_order AS sortOrder,
  created_at AS createdAt,
  updated_at AS updatedAt,
  deleted_at AS deletedAt
`;

const getExecutor = (connection) => connection || getPool();

const mapCategory = (row) => {
  if (!row) {
    return null;
  }

  return {
    ...row,
    basePrice: Number(row.basePrice),
    pricePerKm: Number(row.pricePerKm),
    maxWeightKg: row.maxWeightKg === null ? null : Number(row.maxWeightKg),
    isFragileAllowed: Boolean(row.isFragileAllowed),
    isActive: Boolean(row.isActive),
  };
};

const mapRows = (rows) => rows.map(mapCategory);

const listCategories = async (filters = {}, connection = null) => {
  const executor = getExecutor(connection);
  const params = [];
  const where = ['deleted_at IS NULL'];

  if (!filters.includeInactive) {
    where.push('is_active = 1');
  }

  if (filters.search) {
    where.push('(name LIKE ? OR code LIKE ? OR description LIKE ?)');
    const search = `%${filters.search}%`;
    params.push(search, search, search);
  }

  const [rows] = await executor.execute(
    `
      SELECT ${selectCategoryColumns}
      FROM shipment_categories
      WHERE ${where.join(' AND ')}
      ORDER BY sort_order ASC, name ASC
    `,
    params,
  );

  return mapRows(rows);
};

const findById = async (id, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectCategoryColumns}
      FROM shipment_categories
      WHERE id = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [id],
  );

  return mapCategory(rows[0]);
};

const findByCode = async (code, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectCategoryColumns}
      FROM shipment_categories
      WHERE code = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [code],
  );

  return mapCategory(rows[0]);
};

const createCategory = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO shipment_categories (
        code, name, description, suggested_vehicle_type, icon_key,
        base_price, is_active, sort_order
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.code,
      payload.name,
      payload.description || null,
      payload.vehicleSuggestion || null,
      payload.iconKey || null,
      payload.basePrice,
      payload.isActive ? 1 : 0,
      payload.sortOrder || 0,
    ],
  );

  return findById(result.insertId, connection);
};

const updateCategory = async (id, payload, connection = null) => {
  const executor = getExecutor(connection);
  const setters = [];
  const params = [];

  const add = (column, value) => {
    setters.push(`${column} = ?`);
    params.push(value);
  };

  if (payload.name !== undefined) add('name', payload.name);
  if (payload.description !== undefined) add('description', payload.description || null);
  if (payload.vehicleSuggestion !== undefined) {
    add('suggested_vehicle_type', payload.vehicleSuggestion || null);
  }
  if (payload.iconKey !== undefined) add('icon_key', payload.iconKey || null);
  if (payload.basePrice !== undefined) add('base_price', payload.basePrice);
  if (payload.isActive !== undefined) add('is_active', payload.isActive ? 1 : 0);
  if (payload.sortOrder !== undefined) add('sort_order', payload.sortOrder);

  if (!setters.length) {
    return findById(id, connection);
  }

  params.push(id);

  await executor.execute(
    `
      UPDATE shipment_categories
      SET ${setters.join(', ')}
      WHERE id = ? AND deleted_at IS NULL
    `,
    params,
  );

  return findById(id, connection);
};

const softDeleteCategory = async (id, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      UPDATE shipment_categories
      SET deleted_at = CURRENT_TIMESTAMP, is_active = 0
      WHERE id = ? AND deleted_at IS NULL
    `,
    [id],
  );
};

module.exports = {
  createCategory,
  findByCode,
  findById,
  listCategories,
  softDeleteCategory,
  updateCategory,
};
