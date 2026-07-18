const path = require('path');
const dotenv = require('dotenv');

dotenv.config();

const parseNumber = (value, fallback) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const parseCsv = (value, fallback = []) => {
  if (!value) {
    return fallback;
  }

  return value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
};

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  appName: process.env.APP_NAME || 'CargoConnect API',
  port: parseNumber(process.env.PORT, 5000),
  apiPrefix: process.env.API_PREFIX || '/api/v1',
  bodyLimit: process.env.BODY_LIMIT || '1mb',
  corsOrigins: parseCsv(process.env.CORS_ORIGIN, ['http://localhost:3000']),
  jwt: {
    secret:
      process.env.JWT_SECRET ||
      'development_only_change_this_secret_before_production',
    expiresIn: process.env.JWT_EXPIRES_IN || '1d',
  },
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseNumber(process.env.DB_PORT, 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    name: process.env.DB_NAME || 'cargoconnect_db',
    connectionLimit: parseNumber(process.env.DB_CONNECTION_LIMIT, 10),
  },
  uploads: {
    directory: path.resolve(process.cwd(), process.env.UPLOAD_DIR || 'src/uploads'),
    maxFileSizeMb: parseNumber(process.env.MAX_FILE_SIZE_MB, 5),
  },
  mail: {
    host: process.env.SMTP_HOST || '',
    port: parseNumber(process.env.SMTP_PORT, 587),
    secure: process.env.SMTP_SECURE === 'true',
    user: process.env.SMTP_USER || '',
    password: process.env.SMTP_PASSWORD || '',
    from:
      process.env.MAIL_FROM ||
      'CargoConnect <no-reply@cargoconnect.local>',
  },
};

env.isProduction = env.nodeEnv === 'production';

module.exports = env;
