const successResponse = ({
  res,
  statusCode = 200,
  message = 'Success',
  data = null,
  pagination = null,
  meta = null,
}) => {
  const body = {
    success: true,
    message,
    data,
  };

  const paging = pagination || meta;
  if (paging) {
    body.pagination = paging;
  }

  return res.status(statusCode).json(body);
};

const errorResponse = ({
  res,
  statusCode = 500,
  message = 'Internal server error',
  data = null,
  errors = null,
}) => {
  const body = {
    success: false,
    message,
    data,
  };

  if (errors) {
    body.errors = errors;
  }

  return res.status(statusCode).json(body);
};

module.exports = {
  successResponse,
  errorResponse,
};
