const { USER_ROLES } = require('../constants/auth.constants');
const authorizationModel = require('../models/authorization.model');
const AppError = require('../utils/appError');

const readRequestValue = (req, names) => {
  for (const name of names) {
    if (req.params && req.params[name] !== undefined) {
      return req.params[name];
    }

    if (req.query && req.query[name] !== undefined) {
      return req.query[name];
    }

    if (req.body && req.body[name] !== undefined) {
      return req.body[name];
    }
  }

  return null;
};

const ensureAuthenticated = (req) => {
  if (!req.user) {
    throw new AppError('Authentication is required', 401);
  }
};

const requireResourceIdentifier = (identifiers) => {
  if (!identifiers.some(Boolean)) {
    throw new AppError('Resource identifier is required for access control', 400);
  }
};

const allowAdmin = (req) =>
  req.user &&
  [USER_ROLES.ADMIN, USER_ROLES.DISPATCHER].includes(req.user.role);

const requireCustomerOwnData = (options = {}) => {
  const customerIdParam = options.customerIdParam || 'customerId';
  const customerCodeParam = options.customerCodeParam || 'customerCode';

  return async (req, res, next) => {
    try {
      ensureAuthenticated(req);

      if (allowAdmin(req)) {
        return next();
      }

      if (req.user.role !== USER_ROLES.CUSTOMER) {
        throw new AppError('Customer access is required', 403);
      }

      const customerId = readRequestValue(req, [customerIdParam, 'id']);
      const customerCode = readRequestValue(req, [customerCodeParam]);
      requireResourceIdentifier([customerId, customerCode]);

      const customer = await authorizationModel.customerMatchesUser({
        userId: req.user.id,
        customerId,
        customerCode,
      });

      if (!customer) {
        throw new AppError('You can only access your own customer data', 403);
      }

      req.access = {
        ...(req.access || {}),
        customer,
      };

      return next();
    } catch (error) {
      return next(error);
    }
  };
};

const requireDriverAssignedData = (options = {}) => {
  const shipmentIdParam = options.shipmentIdParam || 'shipmentId';
  const shipmentCodeParam = options.shipmentCodeParam || 'shipmentCode';
  const assignmentIdParam = options.assignmentIdParam || 'assignmentId';
  const assignmentCodeParam = options.assignmentCodeParam || 'assignmentCode';

  return async (req, res, next) => {
    try {
      ensureAuthenticated(req);

      if (allowAdmin(req)) {
        return next();
      }

      if (req.user.role !== USER_ROLES.DRIVER) {
        throw new AppError('Driver access is required', 403);
      }

      const shipmentId = readRequestValue(req, [shipmentIdParam]);
      const shipmentCode = readRequestValue(req, [shipmentCodeParam]);
      const assignmentId = readRequestValue(req, [assignmentIdParam, 'id']);
      const assignmentCode = readRequestValue(req, [assignmentCodeParam]);
      requireResourceIdentifier([
        shipmentId,
        shipmentCode,
        assignmentId,
        assignmentCode,
      ]);

      const assignment = assignmentId || assignmentCode
        ? await authorizationModel.driverOwnsAssignment({
            userId: req.user.id,
            assignmentId,
            assignmentCode,
          })
        : await authorizationModel.driverAssignedToShipment({
            userId: req.user.id,
            shipmentId,
            shipmentCode,
          });

      if (!assignment) {
        throw new AppError('You can only access driver data assigned to you', 403);
      }

      req.access = {
        ...(req.access || {}),
        assignment,
      };

      return next();
    } catch (error) {
      return next(error);
    }
  };
};

const requireShipmentAccess = (options = {}) => {
  const shipmentIdParam = options.shipmentIdParam || 'shipmentId';
  const shipmentCodeParam = options.shipmentCodeParam || 'shipmentCode';

  return async (req, res, next) => {
    try {
      ensureAuthenticated(req);

      if (allowAdmin(req)) {
        return next();
      }

      const shipmentId = readRequestValue(req, [shipmentIdParam, 'id']);
      const shipmentCode = readRequestValue(req, [shipmentCodeParam]);
      requireResourceIdentifier([shipmentId, shipmentCode]);

      if (req.user.role === USER_ROLES.CUSTOMER) {
        const shipment = await authorizationModel.customerOwnsShipment({
          userId: req.user.id,
          shipmentId,
          shipmentCode,
        });

        if (!shipment) {
          throw new AppError('You can only access your own shipments', 403);
        }

        req.access = {
          ...(req.access || {}),
          shipment,
        };

        return next();
      }

      if (req.user.role === USER_ROLES.DRIVER) {
        const assignment = await authorizationModel.driverAssignedToShipment({
          userId: req.user.id,
          shipmentId,
          shipmentCode,
        });

        if (!assignment) {
          throw new AppError('You can only access shipments assigned to you', 403);
        }

        req.access = {
          ...(req.access || {}),
          assignment,
        };

        return next();
      }

      throw new AppError('You do not have permission to access this shipment', 403);
    } catch (error) {
      return next(error);
    }
  };
};

module.exports = {
  requireCustomerOwnData,
  requireDriverAssignedData,
  requireShipmentAccess,
};
