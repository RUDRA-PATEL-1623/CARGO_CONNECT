const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const createAuditLog = async (payload, connection = null) => {
  const executor = getExecutor(connection);

  const [result] = await executor.execute(
    `
      INSERT INTO audit_logs (
        actor_user_id, action, entity_type, entity_id,
        old_values, new_values, ip_address, user_agent
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      payload.actorUserId || null,
      payload.action,
      payload.entityType,
      payload.entityId || null,
      payload.oldValues ? JSON.stringify(payload.oldValues) : null,
      payload.newValues ? JSON.stringify(payload.newValues) : null,
      payload.ipAddress || null,
      payload.userAgent || null,
    ],
  );

  return {
    id: result.insertId,
  };
};

module.exports = {
  createAuditLog,
};
