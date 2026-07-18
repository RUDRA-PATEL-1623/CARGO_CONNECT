const mysql = require('mysql2/promise');

const env = require('./env');

let pool;

const getPool = () => {
  if (!pool) {
    pool = mysql.createPool({
      host: env.db.host,
      port: env.db.port,
      user: env.db.user,
      password: env.db.password,
      database: env.db.name,
      waitForConnections: true,
      connectionLimit: env.db.connectionLimit,
      namedPlaceholders: true,
      timezone: 'Z',
    });
  }

  return pool;
};

const testConnection = async () => {
  const connection = await getPool().getConnection();

  try {
    await connection.ping();
    return {
      host: env.db.host,
      port: env.db.port,
      database: env.db.name,
    };
  } finally {
    connection.release();
  }
};

const closePool = async () => {
  if (pool) {
    await pool.end();
    pool = undefined;
  }
};

module.exports = {
  getPool,
  testConnection,
  closePool,
};
