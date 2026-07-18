const { getPool } = require('../config/database');
const adminSettingsModel = require('../models/adminSettings.model');
const auditLogModel = require('../models/auditLog.model');

const DEFAULT_SETTINGS = [
  {
    settingGroup: 'status_master',
    settingKey: 'shipment_status_flow',
    settingValue: [
      'pending',
      'approved',
      'assigned',
      'accepted',
      'pickup_completed',
      'in_transit',
      'delivered',
      'completed',
    ],
    valueType: 'json',
    description: 'Canonical shipment status flow enforced by the backend.',
    isPublic: false,
  },
  {
    settingGroup: 'notification_settings',
    settingKey: 'notify_customer_on_status_change',
    settingValue: true,
    valueType: 'boolean',
    description: 'Send in-app customer notification on shipment status changes.',
    isPublic: false,
  },
  {
    settingGroup: 'app_settings',
    settingKey: 'support_email',
    settingValue: 'support@cargoconnect.local',
    valueType: 'string',
    description: 'Admin support mailbox shown in local testing flows.',
    isPublic: true,
  },
  {
    settingGroup: 'business_rules',
    settingKey: 'tax_percent',
    settingValue: 18,
    valueType: 'number',
    description: 'Default tax percentage for local price estimates.',
    isPublic: false,
  },
];

const inferValueType = (value) => {
  if (typeof value === 'string') {
    return 'string';
  }

  if (typeof value === 'number') {
    return 'number';
  }

  if (typeof value === 'boolean') {
    return 'boolean';
  }

  return 'json';
};

const groupSettings = (settings) => {
  return settings.reduce((groups, setting) => {
    if (!groups[setting.settingGroup]) {
      groups[setting.settingGroup] = {};
    }

    groups[setting.settingGroup][setting.settingKey] = setting;
    return groups;
  }, {});
};

const normalizeSettingEntries = (payload = {}, actorUserId) => {
  if (Array.isArray(payload.settings)) {
    return payload.settings.map((setting) => ({
      settingGroup: setting.settingGroup,
      settingKey: setting.settingKey,
      settingValue: setting.settingValue,
      valueType: setting.valueType || inferValueType(setting.settingValue),
      description: setting.description || null,
      isPublic: setting.isPublic === true,
      isActive: setting.isActive !== false,
      updatedByUserId: actorUserId,
    }));
  }

  const settingsObject = payload.settings || payload;

  return Object.entries(settingsObject).flatMap(([settingGroup, values]) => {
    if (!values || typeof values !== 'object' || Array.isArray(values)) {
      return [];
    }

    return Object.entries(values).map(([settingKey, settingValue]) => ({
      settingGroup,
      settingKey,
      settingValue,
      valueType: inferValueType(settingValue),
      description: null,
      isPublic: false,
      isActive: true,
      updatedByUserId: actorUserId,
    }));
  });
};

const ensureDefaultSettings = async () => {
  const existing = await adminSettingsModel.listSettings();

  if (existing.length > 0) {
    return existing;
  }

  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    for (const setting of DEFAULT_SETTINGS) {
      await adminSettingsModel.upsertSetting(setting, connection);
    }

    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }

  return adminSettingsModel.listSettings();
};

const getSettings = async (filters = {}) => {
  await ensureDefaultSettings();
  const settings = await adminSettingsModel.listSettings({
    settingGroup: filters.settingGroup || filters.group || null,
  });

  return {
    settings,
    groupedSettings: groupSettings(settings),
    emptyState:
      settings.length === 0
        ? {
            title: 'No settings found',
            message: 'Create settings from the admin panel or seed defaults.',
          }
        : null,
  };
};

const updateSettings = async ({ payload, actorUserId, requestMeta }) => {
  const entries = normalizeSettingEntries(payload, actorUserId);

  if (entries.length === 0) {
    return getSettings();
  }

  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const before = await adminSettingsModel.listSettings({}, connection);

    for (const entry of entries) {
      await adminSettingsModel.upsertSetting(entry, connection);
    }

    const after = await adminSettingsModel.listSettings({}, connection);

    await auditLogModel.createAuditLog(
      {
        actorUserId,
        action: 'settings.updated',
        entityType: 'app_settings',
        entityId: null,
        oldValues: before,
        newValues: entries,
        ...requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      settings: after,
      groupedSettings: groupSettings(after),
      updatedCount: entries.length,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  getSettings,
  updateSettings,
};
