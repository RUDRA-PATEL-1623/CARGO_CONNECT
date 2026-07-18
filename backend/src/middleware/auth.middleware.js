const userModel = require('../models/user.model');
const AppError = require('../utils/appError');
const { verifyAuthToken } = require('../utils/auth');

const getBearerToken = (headerValue) => {
  if (!headerValue) {
    return null;
  }

  const [scheme, token] = headerValue.split(' ');
  return scheme === 'Bearer' && token ? token : null;
};

const requireAuth = async (req, res, next) => {
  try {
    const token = getBearerToken(req.headers.authorization);

    if (!token) {
      throw new AppError('Authentication token is required', 401);
    }

    const payload = verifyAuthToken(token);

    if (payload.purpose) {
      throw new AppError('Authentication token is invalid', 401);
    }

    const user = await userModel.findById(payload.userId);

    if (!user || user.status !== 'active' || user.role !== payload.role) {
      throw new AppError('Authentication token is invalid', 401);
    }

    req.auth = payload;
    req.user = user;
    return next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return next(new AppError('Authentication token is invalid or expired', 401));
    }

    return next(error);
  }
};

module.exports = {
  getBearerToken,
  requireAuth,
};
