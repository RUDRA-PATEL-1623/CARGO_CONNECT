const { closePool, testConnection } = require('../config/database');

const formatConnectionError = (error) => {
  const nestedErrors = Array.isArray(error.errors)
    ? error.errors.map(formatConnectionError).filter(Boolean)
    : [];
  const details = [
    error.message,
    error.code,
    error.errno ? `errno ${error.errno}` : null,
    error.sqlState ? `sqlState ${error.sqlState}` : null,
    ...nestedErrors,
  ].filter(Boolean);

  return details.length > 0
    ? details.join(' | ')
    : error.constructor?.name || 'Unknown MySQL connection error';
};

const run = async () => {
  try {
    const details = await testConnection();
    console.log(
      `MySQL connection OK: ${details.database}@${details.host}:${details.port}`,
    );
    await closePool();
    process.exit(0);
  } catch (error) {
    console.error('MySQL connection failed:', formatConnectionError(error));
    await closePool();
    process.exit(1);
  }
};

run();
