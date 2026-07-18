const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const parseJsonValue = (value) => {
  if (typeof value !== 'string') {
    return value;
  }

  try {
    return JSON.parse(value);
  } catch (error) {
    return value;
  }
};

const mapSetting = (row) => {
  if (!row) {
    return null;
  }

  return {
    id: row.id,
    settingGroup: row.settingGroup,
    settingKey: row.settingKey,
    settingValue: parseJsonValue(row.settingValue),
    valueType: row.valueType,
    description: row.description,
    isPublic: Boolean(row.isPublic),
    isActive: Boolean(row.isActive),
    updatedByUserId: row.updatedByUserId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
};

const listSettings = async ({ settingGroup = null } = {}, connection = null) => {
  const executor = getExecutor(connection);
  const where = ['deleted_at IS NULL'];
  const values = [];

  if (settingGroup) {
    where.push('setting_group = ?');
    values.push(settingGroup);
  }

  const [rows] = await executor.execute(
    `
      SELECT
        id,
        setting_group AS settingGroup,
        setting_key AS settingKey,
        setting_value AS settingValue,
        value_type AS valueType,
        description,
        is_public AS isPublic,
        is_active AS isActive,
        updated_by_user_id AS updatedByUserId,
        created_at AS createdAt,
        updated_at AS updatedAt
      FROM app_settings
      WHERE ${where.join(' AND ')}
      ORDER BY setting_group ASC, setting_key ASC
    `,
    values,
  );

  return rows.map(mapSetting);
};

const upsertSetting = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  await executor.execute(
    `
      INSERT INTO app_settings (
        setting_group, setting_key, setting_value, value_type, description,
        is_public, is_active, updated_by_user_id
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        setting_value = VALUES(setting_value),
        value_type = VALUES(value_type),
        description = VALUES(description),
        is_public = VALUES(is_public),
        is_active = VALUES(is_active),
        updated_by_user_id = VALUES(updated_by_user_id),
        deleted_at = NULL
    `,
    [
      payload.settingGroup,
      payload.settingKey,
      JSON.stringify(payload.settingValue),
      payload.valueType,
      payload.description || null,
      payload.isPublic ? 1 : 0,
      payload.isActive === false ? 0 : 1,
      payload.updatedByUserId || null,
    ],
  );
};

module.exports = {
  listSettings,
  upsertSetting,
};
