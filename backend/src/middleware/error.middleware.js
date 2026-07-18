const { errorResponse } = require('../utils/response');

const errorMiddleware = (error, req, res, next) => {
  if (res.headersSent) {
    return next(error);
  }

  const statusCode = error.statusCode || error.status || 500;
  const isProduction = process.env.NODE_ENV === 'production';

  return errorResponse({
    res,
    statusCode,
    message:
      statusCode === 500 && isProduction
        ? 'Internal server error'
        : error.message || 'Internal server error',
    errors: error.errors || (isProduction ? null : error.stack),
  });
};

module.exports = errorMiddleware;
