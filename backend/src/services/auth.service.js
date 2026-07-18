const { getPool } = require('../config/database');
const {
  OTP_PURPOSES,
  USER_ROLES,
  USER_STATUSES,
  allowedUserRoles,
} = require('../constants/auth.constants');
const authOtpModel = require('../models/authOtp.model');
const customerModel = require('../models/customer.model');
const driverModel = require('../models/driver.model');
const userModel = require('../models/user.model');
const mailService = require('./mail.service');
const AppError = require('../utils/appError');
const {
  compareOtp,
  comparePassword,
  createAuthSession,
  createPublicId,
  generateResetToken,
  generateOtp,
  hashOtp,
  hashPassword,
  normalizeEmail,
  normalizeIdentifier,
  normalizePhone,
  sanitizeUser,
  signAuthToken,
} = require('../utils/auth');

const OTP_TTL_MINUTES = 10;
const RESET_TOKEN_TTL_MINUTES = 15;

const getOtpExpiry = () => {
  return new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000);
};

const getResetTokenExpiry = () => {
  return new Date(Date.now() + RESET_TOKEN_TTL_MINUTES * 60 * 1000);
};

const getDestination = (user) => {
  return user.email || user.phone || user.username;
};

const getVerificationChannel = (destination) => {
  return destination && destination.includes('@') ? 'email' : 'phone';
};

const getCustomerCode = (userId) => {
  return `CUST-${String(userId).padStart(6, '0')}`;
};

const normalizeAddress = (address = {}) => {
  return {
    addressLine1: address.addressLine1 || address.line1 || null,
    addressLine2: address.addressLine2 || address.line2 || null,
    city: address.city || null,
    state: address.state || null,
    postalCode: address.postalCode || address.postal_code || null,
    country: address.country || 'India',
  };
};

const assertRoleAllowed = (role) => {
  if (!allowedUserRoles.includes(role)) {
    throw new AppError('Invalid user role', 422, { role: allowedUserRoles });
  }
};

const assertUniqueIdentity = async ({ email, phone, username }, connection) => {
  if (email && (await userModel.findByEmail(email, { connection }))) {
    throw new AppError('Email is already registered', 409);
  }

  if (phone && (await userModel.findByPhone(phone, { connection }))) {
    throw new AppError('Phone is already registered', 409);
  }

  if (username && (await userModel.findByUsername(username, { connection }))) {
    throw new AppError('Username is already registered', 409);
  }
};

const createAuthOtp = async ({
  user,
  destination,
  purpose,
  connection,
  expiresAt = getOtpExpiry(),
}) => {
  const otp = generateOtp();
  const otpHash = await hashOtp(otp);

  const record = await authOtpModel.createOtp(
    {
      userId: user ? user.id : null,
      destination,
      purpose,
      otpHash,
      expiresAt,
      metadata: { channel: getVerificationChannel(destination) },
    },
    connection,
  );

  return {
    record,
    otp,
  };
};

const createPasswordResetToken = async ({ user, destination, connection }) => {
  const resetToken = generateResetToken();
  const tokenHash = await hashOtp(resetToken);
  const expiresAt = getResetTokenExpiry();

  const record = await authOtpModel.createOtp(
    {
      userId: user.id,
      destination,
      purpose: OTP_PURPOSES.RESET_PASSWORD,
      otpHash: tokenHash,
      expiresAt,
      maxAttempts: 5,
      metadata: {
        channel: getVerificationChannel(destination),
        issuedFor: 'password_reset',
      },
    },
    connection,
  );

  return {
    record,
    resetToken,
    expiresAt,
  };
};

const sendRegistrationOtpSafely = async ({ user, otp }) => {
  try {
    return await mailService.sendCustomerRegistrationOtp({
      to: user.email,
      name: user.name,
      otp,
      expiresInMinutes: OTP_TTL_MINUTES,
    });
  } catch (error) {
    console.error('[mail:error]', error.message);
    return {
      delivered: false,
      error: error.message,
    };
  }
};

const sendPasswordResetOtpSafely = async ({ user, otp }) => {
  const destination = user.email || user.phone || user.username;

  if (!user.email) {
    console.log('[password-reset:fallback]', {
      to: destination,
      subject: 'Reset your CargoConnect password',
      otp,
    });

    return {
      delivered: false,
      fallback: 'console',
    };
  }

  try {
    return await mailService.sendPasswordResetOtp({
      to: user.email,
      name: user.name,
      otp,
      expiresInMinutes: OTP_TTL_MINUTES,
    });
  } catch (error) {
    console.error('[mail:error]', error.message);
    return {
      delivered: false,
      error: error.message,
    };
  }
};

const registerCustomer = async (payload) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    const email = normalizeEmail(payload.email);

    if (!email) {
      throw new AppError('Email is required for customer registration', 422);
    }

    const userInput = {
      publicId: createPublicId(),
      role: USER_ROLES.CUSTOMER,
      name: String(payload.name).trim(),
      username: payload.username ? String(payload.username).trim() : null,
      email,
      phone: normalizePhone(payload.phone),
      passwordHash: await hashPassword(payload.password),
      status: USER_STATUSES.INACTIVE,
    };

    await connection.beginTransaction();
    await assertUniqueIdentity(userInput, connection);

    const user = await userModel.createUser(userInput, connection);
    const customer = await customerModel.createCustomer(
      {
        userId: user.id,
        customerCode: getCustomerCode(user.id),
        ...normalizeAddress(payload.address),
        accountStatus: 'inactive',
      },
      connection,
    );

    await authOtpModel.consumeActiveOtps(
      {
        userId: user.id,
        destination: user.email,
        purpose: OTP_PURPOSES.REGISTER,
      },
      connection,
    );
    const otpResult = await createAuthOtp({
      user,
      destination: user.email,
      purpose: OTP_PURPOSES.REGISTER,
      connection,
    });

    await connection.commit();

    const mail = await sendRegistrationOtpSafely({
      user,
      otp: otpResult.otp,
    });

    return {
      user: sanitizeUser(user),
      customer,
      verification: {
        destination: user.email,
        purpose: OTP_PURPOSES.REGISTER,
        expiresInMinutes: OTP_TTL_MINUTES,
        delivery: mail,
        developmentOtp:
          process.env.NODE_ENV === 'production' ? undefined : otpResult.otp,
      },
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const resendCustomerRegistrationOtp = async ({ email }) => {
  const normalizedEmail = normalizeEmail(email);
  const user = await userModel.findByEmail(normalizedEmail);

  if (!user || user.role !== USER_ROLES.CUSTOMER) {
    throw new AppError('Pending customer registration was not found', 404);
  }

  if (user.emailVerifiedAt || user.status === USER_STATUSES.ACTIVE) {
    throw new AppError('Customer account is already verified', 409);
  }

  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    await authOtpModel.consumeActiveOtps(
      {
        userId: user.id,
        destination: user.email,
        purpose: OTP_PURPOSES.REGISTER,
      },
      connection,
    );
    const otpResult = await createAuthOtp({
      user,
      destination: user.email,
      purpose: OTP_PURPOSES.REGISTER,
      connection,
    });
    await connection.commit();

    const mail = await sendRegistrationOtpSafely({
      user,
      otp: otpResult.otp,
    });

    return {
      destination: user.email,
      purpose: OTP_PURPOSES.REGISTER,
      expiresInMinutes: OTP_TTL_MINUTES,
      delivery: mail,
      developmentOtp:
        process.env.NODE_ENV === 'production' ? undefined : otpResult.otp,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const verifyCustomerRegistrationOtp = async ({ email, otp }) => {
  const normalizedEmail = normalizeEmail(email);
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const user = await userModel.findByEmail(normalizedEmail, { connection });

    if (!user || user.role !== USER_ROLES.CUSTOMER) {
      throw new AppError('Invalid or expired OTP', 422);
    }

    if (user.emailVerifiedAt && user.status === USER_STATUSES.ACTIVE) {
      const customer = await customerModel.findByUserId(user.id, connection);
      await connection.commit();

      return {
        verified: true,
        alreadyVerified: true,
        user: sanitizeUser(user),
        customer,
        token: signAuthToken(user),
      };
    }

    const otpRecord = await authOtpModel.findLatestActive(
      {
        userId: user.id,
        destination: user.email,
        purpose: OTP_PURPOSES.REGISTER,
      },
      connection,
    );

    if (!otpRecord || otpRecord.attempts >= otpRecord.maxAttempts) {
      throw new AppError('Invalid or expired OTP', 422);
    }

    const matches = await compareOtp(otp, otpRecord.otpHash);

    if (!matches) {
      await authOtpModel.incrementAttempts(otpRecord.id, connection);
      throw new AppError('Invalid or expired OTP', 422);
    }

    await authOtpModel.markConsumed(otpRecord.id, connection);
    await userModel.markContactVerified(user.id, 'email', connection);
    const activeUser = await userModel.updateStatus(
      user.id,
      USER_STATUSES.ACTIVE,
      connection,
    );
    const activeCustomer = await customerModel.updateAccountStatusByUserId(
      user.id,
      'active',
      connection,
    );

    await connection.commit();

    return {
      verified: true,
      user: sanitizeUser(activeUser),
      customer: activeCustomer,
      token: signAuthToken(activeUser),
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const register = async (payload) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    const role = payload.role || USER_ROLES.CUSTOMER;
    assertRoleAllowed(role);

    const userInput = {
      publicId: createPublicId(),
      role,
      name: String(payload.name).trim(),
      username: payload.username ? String(payload.username).trim() : null,
      email: normalizeEmail(payload.email),
      phone: normalizePhone(payload.phone),
      passwordHash: await hashPassword(payload.password),
      status: USER_STATUSES.ACTIVE,
    };

    if (!userInput.email && !userInput.phone) {
      throw new AppError('Email or phone is required for registration', 422);
    }

    await connection.beginTransaction();
    await assertUniqueIdentity(userInput, connection);
    const user = await userModel.createUser(userInput, connection);
    const destination = getDestination(user);
    const otpResult = await createAuthOtp({
      user,
      destination,
      purpose: OTP_PURPOSES.REGISTER,
      connection,
    });

    await connection.commit();

    return {
      user: sanitizeUser(user),
      verification: {
        destination,
        purpose: OTP_PURPOSES.REGISTER,
        expiresInMinutes: OTP_TTL_MINUTES,
        developmentOtp: process.env.NODE_ENV === 'production' ? undefined : otpResult.otp,
      },
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const login = async ({ identifier, password, role }) => {
  const normalizedIdentifier = normalizeIdentifier(identifier);
  const user = await userModel.findByIdentifier(normalizedIdentifier, {
    includePassword: true,
  });

  if (!user) {
    throw new AppError('Invalid login credentials', 401);
  }

  if (role && user.role !== role) {
    throw new AppError('Invalid login credentials for selected role', 401);
  }

  if (user.status !== USER_STATUSES.ACTIVE) {
    throw new AppError('User account is not active', 403);
  }

  const passwordMatches = await comparePassword(password, user.passwordHash);

  if (!passwordMatches) {
    throw new AppError('Invalid login credentials', 401);
  }

  const updatedUser = await userModel.updateLastLogin(user.id);

  return {
    user: sanitizeUser(updatedUser),
    token: signAuthToken(user),
  };
};

const authenticateForRole = async ({ identifier, password, role, roles }) => {
  const normalizedIdentifier = normalizeIdentifier(identifier);
  const user = await userModel.findByIdentifier(normalizedIdentifier, {
    includePassword: true,
  });

  const allowedRoles = roles || [role];

  if (!user || !allowedRoles.includes(user.role)) {
    throw new AppError('Invalid login credentials', 401);
  }

  const passwordMatches = await comparePassword(password, user.passwordHash);

  if (!passwordMatches) {
    throw new AppError('Invalid login credentials', 401);
  }

  return user;
};

const buildLoginResponse = async ({ user, profile = null }) => {
  const updatedUser = await userModel.updateLastLogin(user.id);

  return {
    auth: createAuthSession(updatedUser),
    role: updatedUser.role,
    user: sanitizeUser(updatedUser),
    profile,
  };
};

const loginCustomer = async ({ identifier, password }) => {
  const user = await authenticateForRole({
    identifier,
    password,
    role: USER_ROLES.CUSTOMER,
  });

  if (user.status !== USER_STATUSES.ACTIVE || !user.emailVerifiedAt) {
    throw new AppError('Customer account is not verified or active', 403);
  }

  const customer = await customerModel.findByUserId(user.id);

  if (!customer || customer.accountStatus !== 'active') {
    throw new AppError('Customer profile is not active', 403);
  }

  return buildLoginResponse({
    user,
    profile: {
      type: 'customer',
      ...customer,
    },
  });
};

const loginDriver = async ({ identifier, password }) => {
  const user = await authenticateForRole({
    identifier,
    password,
    role: USER_ROLES.DRIVER,
  });

  if (user.status !== USER_STATUSES.ACTIVE) {
    throw new AppError('Driver account is not active', 403);
  }

  const driver = await driverModel.findByUserId(user.id);

  if (!driver || driver.driverStatus !== 'active') {
    throw new AppError('Driver profile is not active', 403);
  }

  return buildLoginResponse({
    user,
    profile: {
      type: 'driver',
      ...driver,
    },
  });
};

const loginAdmin = async ({ identifier, password }) => {
  const user = await authenticateForRole({
    identifier,
    password,
    roles: [USER_ROLES.ADMIN, USER_ROLES.DISPATCHER],
  });

  if (user.status !== USER_STATUSES.ACTIVE) {
    throw new AppError('Admin or dispatcher account is not active', 403);
  }

  return buildLoginResponse({
    user,
    profile: {
      type: user.role,
      name: user.name,
      email: user.email,
      username: user.username,
    },
  });
};

const requestPasswordReset = async ({ identifier }) => {
  const normalizedIdentifier = normalizeIdentifier(identifier);
  const user = await userModel.findByIdentifier(normalizedIdentifier);

  if (!user) {
    return {
      message: 'If the account exists, a reset OTP has been generated.',
    };
  }

  const destination = getDestination(user);
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    await authOtpModel.consumeActiveOtps(
      {
        userId: user.id,
        destination,
        purpose: OTP_PURPOSES.FORGOT_PASSWORD,
      },
      connection,
    );
    const otpResult = await createAuthOtp({
      user,
      destination,
      purpose: OTP_PURPOSES.FORGOT_PASSWORD,
      connection,
    });
    await connection.commit();

    const mail = await sendPasswordResetOtpSafely({
      user,
      otp: otpResult.otp,
    });

    return {
      message: 'If the account exists, a reset OTP has been generated.',
      destination,
      purpose: OTP_PURPOSES.FORGOT_PASSWORD,
      expiresInMinutes: OTP_TTL_MINUTES,
      delivery: mail,
      developmentOtp:
        process.env.NODE_ENV === 'production' ? undefined : otpResult.otp,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const verifyPasswordResetOtp = async ({ identifier, otp }) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const normalizedIdentifier = normalizeIdentifier(identifier);
    const user = await userModel.findByIdentifier(normalizedIdentifier, {
      connection,
    });

    if (!user) {
      throw new AppError('Invalid or expired password reset OTP', 422);
    }

    const destination = getDestination(user);
    const otpRecord = await authOtpModel.findLatestActive(
      {
        userId: user.id,
        destination,
        purpose: OTP_PURPOSES.FORGOT_PASSWORD,
      },
      connection,
    );

    if (!otpRecord || otpRecord.attempts >= otpRecord.maxAttempts) {
      throw new AppError('Invalid or expired password reset OTP', 422);
    }

    const matches = await compareOtp(otp, otpRecord.otpHash);

    if (!matches) {
      await authOtpModel.incrementAttempts(otpRecord.id, connection);
      throw new AppError('Invalid or expired password reset OTP', 422);
    }

    await authOtpModel.markConsumed(otpRecord.id, connection);
    await authOtpModel.consumeActiveOtps(
      {
        userId: user.id,
        destination,
        purpose: OTP_PURPOSES.RESET_PASSWORD,
      },
      connection,
    );
    const tokenResult = await createPasswordResetToken({
      user,
      destination,
      connection,
    });
    await connection.commit();

    return {
      verified: true,
      resetToken: tokenResult.resetToken,
      expiresInMinutes: RESET_TOKEN_TTL_MINUTES,
      expiresAt: tokenResult.expiresAt.toISOString(),
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const verifyOtp = async ({ identifier, otp, purpose }) => {
  const normalizedIdentifier = normalizeIdentifier(identifier);
  const user = await userModel.findByIdentifier(normalizedIdentifier);

  if (!user) {
    throw new AppError('Invalid or expired OTP', 422);
  }

  const destination = getDestination(user);
  const otpRecord = await authOtpModel.findLatestActive({
    userId: user.id,
    destination,
    purpose,
  });

  if (!otpRecord || otpRecord.attempts >= otpRecord.maxAttempts) {
    throw new AppError('Invalid or expired OTP', 422);
  }

  const matches = await compareOtp(otp, otpRecord.otpHash);

  if (!matches) {
    await authOtpModel.incrementAttempts(otpRecord.id);
    throw new AppError('Invalid or expired OTP', 422);
  }

  await authOtpModel.markConsumed(otpRecord.id);

  if (purpose === OTP_PURPOSES.REGISTER) {
    await userModel.markContactVerified(user.id, getVerificationChannel(destination));
  }

  return {
    verified: true,
    user: sanitizeUser(await userModel.findById(user.id)),
  };
};

const resetPassword = async ({ identifier, otp, newPassword }) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const normalizedIdentifier = normalizeIdentifier(identifier);
    const user = await userModel.findByIdentifier(normalizedIdentifier, {
      connection,
    });

    if (!user) {
      throw new AppError('Invalid or expired password reset OTP', 422);
    }

    const destination = getDestination(user);
    const otpRecord = await authOtpModel.findLatestActive(
      {
        userId: user.id,
        destination,
        purpose: OTP_PURPOSES.FORGOT_PASSWORD,
      },
      connection,
    );

    if (!otpRecord || otpRecord.attempts >= otpRecord.maxAttempts) {
      throw new AppError('Invalid or expired password reset OTP', 422);
    }

    const matches = await compareOtp(otp, otpRecord.otpHash);

    if (!matches) {
      await authOtpModel.incrementAttempts(otpRecord.id, connection);
      throw new AppError('Invalid or expired password reset OTP', 422);
    }

    await userModel.updatePassword(
      user.id,
      await hashPassword(newPassword),
      connection,
    );
    await authOtpModel.markConsumed(otpRecord.id, connection);
    await connection.commit();

    return {
      passwordUpdated: true,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const createNewPassword = async ({ identifier, resetToken, newPassword }) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const normalizedIdentifier = normalizeIdentifier(identifier);
    const user = await userModel.findByIdentifier(normalizedIdentifier, {
      connection,
    });

    if (!user) {
      throw new AppError('Invalid or expired reset token', 422);
    }

    const destination = getDestination(user);
    const tokenRecord = await authOtpModel.findLatestActive(
      {
        userId: user.id,
        destination,
        purpose: OTP_PURPOSES.RESET_PASSWORD,
      },
      connection,
    );

    if (!tokenRecord || tokenRecord.attempts >= tokenRecord.maxAttempts) {
      throw new AppError('Invalid or expired reset token', 422);
    }

    const matches = await compareOtp(resetToken, tokenRecord.otpHash);

    if (!matches) {
      await authOtpModel.incrementAttempts(tokenRecord.id, connection);
      throw new AppError('Invalid or expired reset token', 422);
    }

    await userModel.updatePassword(
      user.id,
      await hashPassword(newPassword),
      connection,
    );
    await authOtpModel.markConsumed(tokenRecord.id, connection);
    await connection.commit();

    return {
      passwordUpdated: true,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const changePassword = async ({ userId, currentPassword, newPassword }) => {
  const user = await userModel.findById(userId, { includePassword: true });

  if (!user) {
    throw new AppError('User not found', 404);
  }

  const passwordMatches = await comparePassword(currentPassword, user.passwordHash);

  if (!passwordMatches) {
    throw new AppError('Current password is incorrect', 422);
  }

  const updatedUser = await userModel.updatePassword(
    user.id,
    await hashPassword(newPassword),
  );

  return {
    passwordUpdated: true,
    user: sanitizeUser(updatedUser),
  };
};

module.exports = {
  changePassword,
  createNewPassword,
  login,
  loginAdmin,
  loginCustomer,
  loginDriver,
  register,
  registerCustomer,
  requestPasswordReset,
  resendCustomerRegistrationOtp,
  resetPassword,
  verifyPasswordResetOtp,
  verifyCustomerRegistrationOtp,
  verifyOtp,
};
