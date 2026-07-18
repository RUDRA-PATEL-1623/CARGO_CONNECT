const cors = require('cors');
const express = require('express');
const fs = require('fs');
const helmet = require('helmet');

const env = require('./config/env');
const errorMiddleware = require('./middleware/error.middleware');
const notFoundMiddleware = require('./middleware/notFound.middleware');
const apiRoutes = require('./routes');
const AppError = require('./utils/appError');

const app = express();

fs.mkdirSync(env.uploads.directory, { recursive: true });

app.disable('x-powered-by');
app.use(helmet());
app.use(
  cors({
    origin(origin, callback) {
      if (!origin || env.corsOrigins.includes(origin) || env.corsOrigins.includes('*')) {
        return callback(null, true);
      }

      return callback(new AppError('CORS origin is not allowed', 403));
    },
    credentials: true,
  }),
);
app.use(express.json({ limit: env.bodyLimit }));
app.use(express.urlencoded({ extended: true, limit: env.bodyLimit }));
app.use(
  '/uploads',
  express.static(env.uploads.directory, {
    index: false,
    fallthrough: false,
    setHeaders(res) {
      res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
      res.setHeader('Cache-Control', 'public, max-age=86400');
    },
  }),
);

app.use(env.apiPrefix, apiRoutes);
app.use(notFoundMiddleware);
app.use(errorMiddleware);

module.exports = app;
