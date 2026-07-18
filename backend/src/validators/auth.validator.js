const { body } = require('express-validator');

const {
  PASSWORD_RULES,
  allowedOtpPurposes,
  allowedUserRoles,
} = require('../constants/auth.constants');

const passwordValidator = (field = 'password') => {
  return body(field)
    .isString()
    .withMessage('Password is required')
    .isLength({
      min: PASSWORD_RULES.minLength,
      max: PASSWORD_RULES.maxLength,
    })
    .withMessage(
      `Password must be ${PASSWORD_RULES.minLength}-${PASSWORD_RULES.maxLength} characters`,
    )
    .matches(/[a-z]/)
    .withMessage('Password must include a lowercase letter')
    .matches(/[A-Z]/)
    .withMessage('Password must include an uppercase letter')
    .matches(/[0-9]/)
    .withMessage('Password must include a number')
    .matches(/[^A-Za-z0-9]/)
    .withMessage('Password must include a special character');
};

const confirmPasswordValidator = (field = 'confirmPassword', source = 'password') => {
  return body(field)
    .isString()
    .withMessage('Confirm password is required')
    .custom((value, { req }) => value === req.body[source])
    .withMessage('Passwords do not match');
};

const identifierValidator = () => {
  return body('identifier')
    .trim()
    .notEmpty()
    .withMessage('Email, phone, or username is required')
    .isLength({ max: 160 })
    .withMessage('Identifier must be 160 characters or less');
};

const registerValidator = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 120 })
    .withMessage('Name must be 2-120 characters'),
  body('role')
    .optional()
    .isIn(allowedUserRoles)
    .withMessage(`Role must be one of: ${allowedUserRoles.join(', ')}`),
  body('username')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 3, max: 80 })
    .withMessage('Username must be 3-80 characters')
    .matches(/^[A-Za-z0-9._-]+$/)
    .withMessage('Username can only contain letters, numbers, dots, dashes, and underscores'),
  body('email')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isEmail()
    .withMessage('Valid email is required')
    .normalizeEmail(),
  body('phone')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 7, max: 30 })
    .withMessage('Phone must be 7-30 characters')
    .matches(/^\+?[0-9\s-]+$/)
    .withMessage('Phone can include digits, spaces, dashes, and leading plus'),
  body()
    .custom((value) => Boolean(value.email || value.phone))
    .withMessage('Email or phone is required'),
  passwordValidator('password'),
  confirmPasswordValidator('confirmPassword', 'password'),
];

const loginValidator = [
  identifierValidator(),
  body('role')
    .optional()
    .isIn(allowedUserRoles)
    .withMessage(`Role must be one of: ${allowedUserRoles.join(', ')}`),
  body('password').isString().notEmpty().withMessage('Password is required'),
];

const createRoleAwareLoginValidator = () => [
  identifierValidator(),
  body('password').isString().notEmpty().withMessage('Password is required'),
];

const customerLoginValidator = createRoleAwareLoginValidator();
const driverLoginValidator = createRoleAwareLoginValidator();
const adminLoginValidator = createRoleAwareLoginValidator();

const otpVerifyValidator = [
  identifierValidator(),
  body('purpose')
    .isIn(allowedOtpPurposes)
    .withMessage(`OTP purpose must be one of: ${allowedOtpPurposes.join(', ')}`),
  body('otp')
    .trim()
    .matches(/^[0-9]{6}$/)
    .withMessage('OTP must be a 6-digit code'),
];

const forgotPasswordValidator = [identifierValidator()];

const verifyResetOtpValidator = [
  identifierValidator(),
  body('otp')
    .trim()
    .matches(/^[0-9]{6}$/)
    .withMessage('OTP must be a 6-digit code'),
];

const resetPasswordValidator = [
  identifierValidator(),
  body('otp')
    .trim()
    .matches(/^[0-9]{6}$/)
    .withMessage('OTP must be a 6-digit code'),
  passwordValidator('newPassword'),
  confirmPasswordValidator('confirmPassword', 'newPassword'),
];

const createNewPasswordValidator = [
  identifierValidator(),
  body('resetToken')
    .trim()
    .notEmpty()
    .withMessage('Reset token is required')
    .isLength({ min: 32, max: 128 })
    .withMessage('Reset token is invalid'),
  passwordValidator('newPassword'),
  confirmPasswordValidator('confirmPassword', 'newPassword'),
];

const changePasswordValidator = [
  body('currentPassword')
    .isString()
    .notEmpty()
    .withMessage('Current password is required'),
  passwordValidator('newPassword'),
  confirmPasswordValidator('confirmPassword', 'newPassword'),
];

const customerRegistrationValidator = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 120 })
    .withMessage('Name must be 2-120 characters'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Valid email is required')
    .normalizeEmail(),
  body('phone')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 7, max: 30 })
    .withMessage('Phone must be 7-30 characters')
    .matches(/^\+?[0-9\s-]+$/)
    .withMessage('Phone can include digits, spaces, dashes, and leading plus'),
  body('username')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ min: 3, max: 80 })
    .withMessage('Username must be 3-80 characters')
    .matches(/^[A-Za-z0-9._-]+$/)
    .withMessage('Username can only contain letters, numbers, dots, dashes, and underscores'),
  body('address')
    .optional({ nullable: true })
    .isObject()
    .withMessage('Address must be an object'),
  body('address.addressLine1')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 180 })
    .withMessage('Address line 1 must be 180 characters or less'),
  body('address.addressLine2')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 180 })
    .withMessage('Address line 2 must be 180 characters or less'),
  body('address.city')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('City must be 100 characters or less'),
  body('address.state')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 100 })
    .withMessage('State must be 100 characters or less'),
  body('address.postalCode')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 20 })
    .withMessage('Postal code must be 20 characters or less'),
  body('address.country')
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isLength({ max: 80 })
    .withMessage('Country must be 80 characters or less'),
  body('acceptTerms')
    .custom((value) => value === true || value === 'true')
    .withMessage('Terms must be accepted'),
  passwordValidator('password'),
  confirmPasswordValidator('confirmPassword', 'password'),
];

const customerEmailOtpVerifyValidator = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Valid email is required')
    .normalizeEmail(),
  body('otp')
    .trim()
    .matches(/^[0-9]{6}$/)
    .withMessage('OTP must be a 6-digit code'),
];

const customerResendRegistrationOtpValidator = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Valid email is required')
    .normalizeEmail(),
];

module.exports = {
  adminLoginValidator,
  changePasswordValidator,
  createNewPasswordValidator,
  customerLoginValidator,
  customerEmailOtpVerifyValidator,
  customerRegistrationValidator,
  customerResendRegistrationOtpValidator,
  driverLoginValidator,
  forgotPasswordValidator,
  loginValidator,
  otpVerifyValidator,
  registerValidator,
  resetPasswordValidator,
  verifyResetOtpValidator,
};
