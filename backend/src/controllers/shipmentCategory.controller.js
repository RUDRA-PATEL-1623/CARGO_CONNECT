const shipmentCategoryService = require('../services/shipmentCategory.service');
const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/response');

const listCustomerCategories = asyncHandler(async (req, res) => {
  const categories = await shipmentCategoryService.listCustomerCategories();

  return successResponse({
    res,
    message: 'Shipment categories fetched successfully.',
    data: categories,
  });
});

const listAdminCategories = asyncHandler(async (req, res) => {
  const categories = await shipmentCategoryService.listAdminCategories({
    includeInactive: req.query.includeInactive === 'true',
    search: req.query.search,
  });

  return successResponse({
    res,
    message: 'Admin shipment categories fetched successfully.',
    data: categories,
  });
});

const getAdminCategory = asyncHandler(async (req, res) => {
  const category = await shipmentCategoryService.getAdminCategory(
    req.params.categoryId,
  );

  return successResponse({
    res,
    message: 'Shipment category fetched successfully.',
    data: category,
  });
});

const createAdminCategory = asyncHandler(async (req, res) => {
  const category = await shipmentCategoryService.createAdminCategory(req.body);

  return successResponse({
    res,
    statusCode: 201,
    message: 'Shipment category created successfully.',
    data: category,
  });
});

const updateAdminCategory = asyncHandler(async (req, res) => {
  const category = await shipmentCategoryService.updateAdminCategory(
    req.params.categoryId,
    req.body,
  );

  return successResponse({
    res,
    message: 'Shipment category updated successfully.',
    data: category,
  });
});

const deleteAdminCategory = asyncHandler(async (req, res) => {
  const result = await shipmentCategoryService.deleteAdminCategory(
    req.params.categoryId,
  );

  return successResponse({
    res,
    message: 'Shipment category deleted successfully.',
    data: result,
  });
});

module.exports = {
  createAdminCategory,
  deleteAdminCategory,
  getAdminCategory,
  listAdminCategories,
  listCustomerCategories,
  updateAdminCategory,
};
