const adminCustomerService = require('../services/adminCustomer.service');
const asyncHandler = require('../utils/asyncHandler');
const { getRequestMeta } = require('../utils/requestMeta');
const { successResponse } = require('../utils/response');

const listCustomers = asyncHandler(async (req, res) => {
  const result = await adminCustomerService.listCustomers(req.query);

  return successResponse({
    res,
    message: 'Admin customers fetched successfully.',
    data: result,
  });
});

const getCustomerDetails = asyncHandler(async (req, res) => {
  const result = await adminCustomerService.getCustomerDetails(
    req.params.customerId,
  );

  return successResponse({
    res,
    message: 'Admin customer details fetched successfully.',
    data: result,
  });
});

const activateCustomer = asyncHandler(async (req, res) => {
  const result = await adminCustomerService.activateCustomer({
    customerId: req.params.customerId,
    adminUser: req.user,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Customer activated successfully.',
    data: result,
  });
});

const deactivateCustomer = asyncHandler(async (req, res) => {
  const result = await adminCustomerService.deactivateCustomer({
    customerId: req.params.customerId,
    adminUser: req.user,
    reason: req.body.reason,
    requestMeta: getRequestMeta(req),
  });

  return successResponse({
    res,
    message: 'Customer deactivated successfully.',
    data: result,
  });
});

module.exports = {
  activateCustomer,
  deactivateCustomer,
  getCustomerDetails,
  listCustomers,
};
