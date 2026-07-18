const app = require('./app');
const env = require('./config/env');
const { closePool, testConnection } = require('./config/database');

let server;

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

const handleServerError = (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(`Port ${env.port} is already in use.`);
    console.error(
      `Stop the process using port ${env.port}, or set PORT to another value in backend/.env.`,
    );
    console.error(`Windows check: netstat -ano | findstr :${env.port}`);
  } else {
    console.error(`HTTP server failed to start: ${error.message}`);
  }

  closePool()
    .catch((poolError) => {
      console.error(`MySQL pool close warning: ${poolError.message}`);
    })
    .finally(() => {
      process.exit(1);
    });
};

const startServer = async () => {
  try {
    await testConnection();
    console.log('MySQL connection verified.');
  } catch (error) {
    console.warn(`MySQL connection warning: ${formatConnectionError(error)}`);
    console.warn('API will still start so non-database routes can be tested.');
  }

  server = app.listen(env.port, () => {
    console.log(`${env.appName} listening on port ${env.port}`);
    console.log(`Route registry: http://localhost:${env.port}${env.apiPrefix}`);
  });

  server.on('error', handleServerError);
};

const shutdown = async (signal) => {
  console.log(`${signal} received. Shutting down server...`);

  if (server) {
    server.close(async () => {
      await closePool();
      console.log('HTTP server and MySQL pool closed.');
      process.exit(0);
    });
    return;
  }

  await closePool();
  process.exit(0);
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

startServer();
