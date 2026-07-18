const customerFeedbackService = require('../services/customerFeedback.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const submitFeedback = asyncHandler(async (req, res) => {
  const result = await customerFeedbackService.submitFeedback(req.user.id, req.body);

  return successResponse({
    res,
    statusCode: 201,
    message: 'Feedback submitted successfully.',
    data: result,
  });
});

const listFeedback = asyncHandler(async (req, res) => {
  const result = await customerFeedbackService.listFeedback(req.user.id, req.query);

  return successResponse({
    res,
    message: 'Customer feedback fetched successfully.',
    data: result,
  });
});

module.exports = {
  listFeedback,
  submitFeedback,
};
