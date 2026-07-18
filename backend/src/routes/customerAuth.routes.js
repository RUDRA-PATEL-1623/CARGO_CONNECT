const express = require('express');

const customerAuthController = require('../controllers/customerAuth.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  adminLoginValidator,
  changePasswordValidator,
  createNewPasswordValidator,
  customerLoginValidator,
  customerEmailOtpVerifyValidator,
  customerRegistrationValidator,
  customerResendRegistrationOtpValidator,
  driverLoginValidator,
  forgotPasswordValidator,
  resetPasswordValidator,
  verifyResetOtpValidator,
} = require('../validators/auth.validator');

const router = express.Router();

/**
 * @route POST /api/v1/auth/customer/register
 * @description Register a customer in inactive state and send an email OTP.
 * @body { name, email, phone?, password, confirmPassword, address?, acceptTerms }
 */
router.post(
  '/customer/register',
  customerRegistrationValidator,
  validateRequest,
  customerAuthController.registerCustomer,
);

/**
 * @route POST /api/v1/auth/customer/login
 * @description Login a verified active customer account.
 * @body { identifier, password }
 */
router.post(
  '/customer/login',
  customerLoginValidator,
  validateRequest,
  customerAuthController.loginCustomer,
);

/**
 * @route POST /api/v1/auth/customer/verify-otp
 * @description Verify customer registration OTP and activate the account.
 * @body { email, otp }
 */
router.post(
  '/customer/verify-otp',
  customerEmailOtpVerifyValidator,
  validateRequest,
  customerAuthController.verifyRegistrationOtp,
);

/**
 * @route POST /api/v1/auth/customer/resend-otp
 * @description Resend email OTP for a pending customer registration.
 * @body { email }
 */
router.post(
  '/customer/resend-otp',
  customerResendRegistrationOtpValidator,
  validateRequest,
  customerAuthController.resendRegistrationOtp,
);

/**
 * @route POST /api/v1/auth/driver/login
 * @description Login an admin-created active driver account.
 * @body { identifier, password }
 */
router.post(
  '/driver/login',
  driverLoginValidator,
  validateRequest,
  customerAuthController.loginDriver,
);

/**
 * @route POST /api/v1/auth/admin/login
 * @description Login an active admin account.
 * @body { identifier, password }
 */
router.post(
  '/admin/login',
  adminLoginValidator,
  validateRequest,
  customerAuthController.loginAdmin,
);

/**
 * @route POST /api/v1/auth/forgot-password
 * @description Generate a password reset OTP with expiry.
 * @body { identifier }
 */
router.post(
  '/forgot-password',
  forgotPasswordValidator,
  validateRequest,
  customerAuthController.forgotPassword,
);

/**
 * @route POST /api/v1/auth/verify-reset-otp
 * @description Verify password reset OTP and issue a short-lived reset token.
 * @body { identifier, otp }
 */
router.post(
  '/verify-reset-otp',
  verifyResetOtpValidator,
  validateRequest,
  customerAuthController.verifyResetOtp,
);

/**
 * @route POST /api/v1/auth/create-new-password
 * @description Create a new password using a verified reset token.
 * @body { identifier, resetToken, newPassword, confirmPassword }
 */
router.post(
  '/create-new-password',
  createNewPasswordValidator,
  validateRequest,
  customerAuthController.createNewPassword,
);

/**
 * @route POST /api/v1/auth/reset-password
 * @description Reset password directly with a verified OTP.
 * @body { identifier, otp, newPassword, confirmPassword }
 */
router.post(
  '/reset-password',
  resetPasswordValidator,
  validateRequest,
  customerAuthController.resetPassword,
);

/**
 * @route POST /api/v1/auth/change-password
 * @description Change password for the authenticated user.
 * @header Authorization: Bearer <token>
 * @body { currentPassword, newPassword, confirmPassword }
 */
router.post(
  '/change-password',
  requireAuth,
  changePasswordValidator,
  validateRequest,
  customerAuthController.changePassword,
);

module.exports = router;
