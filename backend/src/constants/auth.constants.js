const USER_ROLES = Object.freeze({
  ADMIN: 'admin',
  DISPATCHER: 'dispatcher',
  CUSTOMER: 'customer',
  DRIVER: 'driver',
});

const USER_STATUSES = Object.freeze({
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  SUSPENDED: 'suspended',
});

const OTP_PURPOSES = Object.freeze({
  REGISTER: 'register',
  LOGIN: 'login',
  FORGOT_PASSWORD: 'forgot_password',
  RESET_PASSWORD: 'reset_password',
  CHANGE_PASSWORD: 'change_password',
});

const PASSWORD_RULES = Object.freeze({
  minLength: 8,
  maxLength: 72,
});

module.exports = {
  USER_ROLES,
  USER_STATUSES,
  OTP_PURPOSES,
  PASSWORD_RULES,
  allowedUserRoles: Object.values(USER_ROLES),
  allowedOtpPurposes: Object.values(OTP_PURPOSES),
};
