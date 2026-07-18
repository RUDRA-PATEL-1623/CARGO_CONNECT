const { getPool } = require('../config/database');
const customerModel = require('../models/customer.model');
const userModel = require('../models/user.model');
const AppError = require('../utils/appError');
const { normalizePhone, sanitizeUser } = require('../utils/auth');

const formatAddress = (customer) => ({
  addressLine1: customer.addressLine1,
  addressLine2: customer.addressLine2,
  city: customer.city,
  state: customer.state,
  postalCode: customer.postalCode,
  country: customer.country,
});

const buildProfile = ({ user, customer }) => ({
  user: sanitizeUser(user),
  customer,
  profile: {
    id: customer.id,
    customerCode: customer.customerCode,
    name: user.name,
    email: user.email,
    phone: user.phone,
    avatarUrl: user.avatarUrl,
    accountStatus: customer.accountStatus,
    emailVerifiedAt: user.emailVerifiedAt,
    phoneVerifiedAt: user.phoneVerifiedAt,
    address: formatAddress(customer),
    stats: {
      totalShipments: Number(customer.totalShipments || 0),
    },
  },
});

const getActiveCustomerProfile = async (userId, connection = null) => {
  const customer = await customerModel.findByUserId(userId, connection);

  if (!customer || customer.accountStatus !== 'active') {
    throw new AppError('Active customer profile is required', 403);
  }

  return customer;
};

const getProfile = async (userId) => {
  const [user, customer] = await Promise.all([
    userModel.findById(userId),
    getActiveCustomerProfile(userId),
  ]);

  if (!user) {
    throw new AppError('Customer user was not found', 404);
  }

  return buildProfile({ user, customer });
};

const updateProfile = async (userId, payload) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const currentUser = await userModel.findById(userId, { connection });
    const currentCustomer = await getActiveCustomerProfile(userId, connection);

    if (!currentUser) {
      throw new AppError('Customer user was not found', 404);
    }

    const phone = payload.phone === undefined
      ? currentUser.phone
      : normalizePhone(payload.phone);

    if (phone && phone !== currentUser.phone) {
      const existingPhoneUser = await userModel.findByPhone(phone, { connection });

      if (existingPhoneUser && existingPhoneUser.id !== currentUser.id) {
        throw new AppError('Phone is already registered', 409);
      }
    }

    const updatedUser = await userModel.updateProfile(
      userId,
      {
        name: String(payload.name).trim(),
        phone,
        avatarUrl: payload.avatarUrl || currentUser.avatarUrl,
      },
      connection,
    );
    const updatedCustomer = await customerModel.updateProfileByUserId(
      userId,
      {
        addressLine1: payload.addressLine1 ?? currentCustomer.addressLine1,
        addressLine2: payload.addressLine2 ?? currentCustomer.addressLine2,
        city: payload.city ?? currentCustomer.city,
        state: payload.state ?? currentCustomer.state,
        postalCode: payload.postalCode ?? currentCustomer.postalCode,
        country: payload.country ?? currentCustomer.country,
      },
      connection,
    );

    await connection.commit();

    return buildProfile({
      user: updatedUser,
      customer: updatedCustomer,
    });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  getActiveCustomerProfile,
  getProfile,
  updateProfile,
};
