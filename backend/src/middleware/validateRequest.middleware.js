const fs = require('fs');
const { validationResult } = require('express-validator');

const { errorResponse } = require('../utils/response');

const formatValidationErrors = (result) => result
  .array({ onlyFirstError: true })
  .map((error) => ({
    field: error.path || error.param || null,
    location: error.location,
    message: error.msg,
  }));

const validateRequest = (req, res, next) => {
  const result = validationResult(req);

  if (result.isEmpty()) {
    return next();
  }

  if (req.file?.path) {
    fs.unlink(req.file.path, () => {});
  }

  return errorResponse({
    res,
    statusCode: 422,
    message: 'Validation failed',
    errors: formatValidationErrors(result),
  });
};

module.exports = validateRequest;
