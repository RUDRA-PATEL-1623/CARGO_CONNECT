const express = require('express');

const { USER_ROLES } = require('../constants/auth.constants');
const shipmentCategoryController = require('../controllers/shipmentCategory.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin, requireRoles } = require('../middleware/role.middleware');
const validateRequest = require('../middleware/validateRequest.middleware');
const {
  adminCategoryListValidator,
  categoryIdParamValidator,
  createCategoryValidator,
  updateCategoryValidator,
} = require('../validators/shipmentCategory.validator');

const router = express.Router();

/**
 * @route GET /api/v1/shipment-categories
 * @description Customer-facing active shipment category list.
 */
router.get(
  '/shipment-categories',
  requireAuth,
  requireRoles(USER_ROLES.CUSTOMER, USER_ROLES.ADMIN),
  shipmentCategoryController.listCustomerCategories,
);

/**
 * @route GET /api/v1/admin/shipment-categories
 * @description Admin list for shipment categories.
 */
router.get(
  '/admin/shipment-categories',
  requireAuth,
  requireAdmin,
  adminCategoryListValidator,
  validateRequest,
  shipmentCategoryController.listAdminCategories,
);

/**
 * @route POST /api/v1/admin/shipment-categories
 * @description Admin create shipment category.
 */
router.post(
  '/admin/shipment-categories',
  requireAuth,
  requireAdmin,
  createCategoryValidator,
  validateRequest,
  shipmentCategoryController.createAdminCategory,
);

/**
 * @route GET /api/v1/admin/shipment-categories/:categoryId
 * @description Admin get shipment category by id.
 */
router.get(
  '/admin/shipment-categories/:categoryId',
  requireAuth,
  requireAdmin,
  categoryIdParamValidator,
  validateRequest,
  shipmentCategoryController.getAdminCategory,
);

/**
 * @route PATCH /api/v1/admin/shipment-categories/:categoryId
 * @description Admin update shipment category.
 */
router.patch(
  '/admin/shipment-categories/:categoryId',
  requireAuth,
  requireAdmin,
  updateCategoryValidator,
  validateRequest,
  shipmentCategoryController.updateAdminCategory,
);

/**
 * @route DELETE /api/v1/admin/shipment-categories/:categoryId
 * @description Admin soft delete shipment category.
 */
router.delete(
  '/admin/shipment-categories/:categoryId',
  requireAuth,
  requireAdmin,
  categoryIdParamValidator,
  validateRequest,
  shipmentCategoryController.deleteAdminCategory,
);

module.exports = router;
