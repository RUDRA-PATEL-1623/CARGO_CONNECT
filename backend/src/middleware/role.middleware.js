const { USER_ROLES } = require('../constants/auth.constants');
const AppError = require('../utils/appError');

const requireRoles = (...roles) => {
  const allowedRoles = roles.flat();

  return (req, res, next) => {
    if (!req.user) {
      return next(new AppError('Authentication is required', 401));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(new AppError('You do not have permission to access this resource', 403));
    }

    return next();
  };
};

const requireAdmin = requireRoles(USER_ROLES.ADMIN, USER_ROLES.DISPATCHER);
const requireAdminOnly = requireRoles(USER_ROLES.ADMIN);
const requireCustomer = requireRoles(USER_ROLES.CUSTOMER);
const requireDriver = requireRoles(USER_ROLES.DRIVER);

module.exports = {
  requireAdmin,
  requireAdminOnly,
  requireCustomer,
  requireDriver,
  requireRoles,
};
