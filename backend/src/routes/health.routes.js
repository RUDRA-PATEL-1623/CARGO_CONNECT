const express = require('express');

const env = require('../config/env');
const { testConnection } = require('../config/database');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const router = express.Router();

/**
 * @route GET /api/v1/health
 * @description Confirms the API process is running. This is a foundation endpoint only.
 * @sampleResponse 200
 * {
 *   "success": true,
 *   "message": "CargoConnect API is running",
 *   "data": { "service": "CargoConnect API", "environment": "development" }
 * }
 */
router.get('/', (req, res) => {
  return successResponse({
    res,
    message: `${env.appName} is running`,
    data: {
      service: env.appName,
      environment: env.nodeEnv,
      uptimeSeconds: Math.round(process.uptime()),
    },
  });
});

/**
 * @route GET /api/v1/health/db
 * @description Verifies MySQL connectivity using the configured pool.
 * @sampleResponse 200
 * {
 *   "success": true,
 *   "message": "Database connection is healthy",
 *   "data": { "host": "localhost", "port": 3306, "database": "cargoconnect" }
 * }
 */
router.get(
  '/db',
  asyncHandler(async (req, res) => {
    let details;

    try {
      details = await testConnection();
    } catch (error) {
      const dbError = new Error(
        `Database connection failed: ${
          error.code || error.message || 'Unable to connect to MySQL'
        }`,
      );
      dbError.statusCode = 503;
      dbError.errors = {
        host: env.db.host,
        port: env.db.port,
        database: env.db.name,
      };
      throw dbError;
    }

    return successResponse({
      res,
      message: 'Database connection is healthy',
      data: details,
    });
  }),
);

module.exports = router;
