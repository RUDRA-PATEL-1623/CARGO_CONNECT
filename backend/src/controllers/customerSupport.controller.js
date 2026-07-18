const customerSupportService = require('../services/customerSupport.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const createIssue = asyncHandler(async (req, res) => {
  const result = await customerSupportService.createIssue(req.user.id, req.body);

  return successResponse({
    res,
    statusCode: 201,
    message: 'Support issue created successfully.',
    data: result,
  });
});

const listIssues = asyncHandler(async (req, res) => {
  const result = await customerSupportService.listIssues(req.user.id, req.query);

  return successResponse({
    res,
    message: 'Support issues fetched successfully.',
    data: result,
  });
});

module.exports = {
  createIssue,
  listIssues,
};
