const adminPaymentService = require('../services/adminPayment.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const listPayments = asyncHandler(async (req, res) => {
  const result = await adminPaymentService.listPayments(req.query);

  return successResponse({
    res,
    message: 'Admin payments fetched successfully.',
    data: result,
  });
});

const getPaymentDetails = asyncHandler(async (req, res) => {
  const result = await adminPaymentService.getPaymentDetails(req.params.paymentId);

  return successResponse({
    res,
    message: 'Admin payment details fetched successfully.',
    data: result,
  });
});

module.exports = {
  getPaymentDetails,
  listPayments,
};
