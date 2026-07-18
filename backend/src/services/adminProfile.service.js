const userModel = require('../models/user.model');
const { sanitizeUser } = require('../utils/auth');
const AppError = require('../utils/appError');

const getProfile = async (userId) => {
  const user = await userModel.findById(userId);

  if (!user || !['admin', 'dispatcher'].includes(user.role)) {
    throw new AppError('Admin profile was not found', 404);
  }

  return {
    profile: sanitizeUser(user),
    permissions: {
      canManageShipments: true,
      canManageDrivers: true,
      canManageVehicles: true,
      canManageCustomers: true,
      canViewReports: true,
      canManageSettings: true,
    },
  };
};

const logout = async () => ({
  revoked: false,
  message: 'Token-safe logout acknowledged. Discard the JWT on the client.',
});

module.exports = {
  getProfile,
  logout,
};
