const authService = require('../services/auth.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const registerCustomer = asyncHandler(async (req, res) => {
  const result = await authService.registerCustomer(req.body);

  return successResponse({
    res,
    statusCode: 201,
    message: 'Customer registration created. Verify the email OTP to activate the account.',
    data: result,
  });
});

const loginCustomer = asyncHandler(async (req, res) => {
  const result = await authService.loginCustomer(req.body);

  return successResponse({
    res,
    message: 'Customer login successful.',
    data: result,
  });
});

const loginDriver = asyncHandler(async (req, res) => {
  const result = await authService.loginDriver(req.body);

  return successResponse({
    res,
    message: 'Driver login successful.',
    data: result,
  });
});

const loginAdmin = asyncHandler(async (req, res) => {
  const result = await authService.loginAdmin(req.body);

  return successResponse({
    res,
    message: 'Admin login successful.',
    data: result,
  });
});

const verifyRegistrationOtp = asyncHandler(async (req, res) => {
  const result = await authService.verifyCustomerRegistrationOtp(req.body);

  return successResponse({
    res,
    message: 'Customer account verified successfully.',
    data: result,
  });
});

const resendRegistrationOtp = asyncHandler(async (req, res) => {
  const result = await authService.resendCustomerRegistrationOtp(req.body);

  return successResponse({
    res,
    message: 'Customer registration OTP resent.',
    data: result,
  });
});

const forgotPassword = asyncHandler(async (req, res) => {
  const result = await authService.requestPasswordReset(req.body);

  return successResponse({
    res,
    message: result.message || 'If the account exists, a reset OTP has been generated.',
    data: result,
  });
});

const verifyResetOtp = asyncHandler(async (req, res) => {
  const result = await authService.verifyPasswordResetOtp(req.body);

  return successResponse({
    res,
    message: 'Password reset OTP verified successfully.',
    data: result,
  });
});

const createNewPassword = asyncHandler(async (req, res) => {
  const result = await authService.createNewPassword(req.body);

  return successResponse({
    res,
    message: 'Password updated successfully.',
    data: result,
  });
});

const resetPassword = asyncHandler(async (req, res) => {
  const result = await authService.resetPassword(req.body);

  return successResponse({
    res,
    message: 'Password reset successfully.',
    data: result,
  });
});

const changePassword = asyncHandler(async (req, res) => {
  const result = await authService.changePassword({
    userId: req.user.id,
    currentPassword: req.body.currentPassword,
    newPassword: req.body.newPassword,
  });

  return successResponse({
    res,
    message: 'Password changed successfully.',
    data: result,
  });
});

module.exports = {
  changePassword,
  createNewPassword,
  forgotPassword,
  loginAdmin,
  loginCustomer,
  loginDriver,
  registerCustomer,
  resetPassword,
  resendRegistrationOtp,
  verifyResetOtp,
  verifyRegistrationOtp,
};
