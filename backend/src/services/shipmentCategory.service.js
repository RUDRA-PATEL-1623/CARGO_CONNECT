const shipmentCategoryModel = require('../models/shipmentCategory.model');
const AppError = require('../utils/appError');

const slugifyCode = (value) => {
  return String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 40);
};

const normalizeBoolean = (value) => {
  if (value === undefined) {
    return undefined;
  }

  return value === true || value === 'true' || value === 1 || value === '1';
};

const normalizePayload = (payload) => ({
  code: payload.code ? slugifyCode(payload.code) : undefined,
  name: payload.name ? String(payload.name).trim() : undefined,
  description:
    payload.description === undefined
      ? undefined
      : String(payload.description || '').trim(),
  vehicleSuggestion:
    payload.vehicleSuggestion === undefined
      ? undefined
      : payload.vehicleSuggestion || null,
  iconKey:
    payload.iconKey === undefined ? undefined : String(payload.iconKey || '').trim(),
  basePrice:
    payload.basePrice === undefined ? undefined : Number(payload.basePrice),
  isActive: normalizeBoolean(payload.isActive),
  sortOrder:
    payload.sortOrder === undefined ? undefined : Number(payload.sortOrder),
});

const listCustomerCategories = async () => {
  return shipmentCategoryModel.listCategories({ includeInactive: false });
};

const listAdminCategories = async (filters) => {
  return shipmentCategoryModel.listCategories({
    includeInactive: filters.includeInactive === true,
    search: filters.search,
  });
};

const getAdminCategory = async (categoryId) => {
  const category = await shipmentCategoryModel.findById(categoryId);

  if (!category) {
    throw new AppError('Shipment category not found', 404);
  }

  return category;
};

const createAdminCategory = async (payload) => {
  const normalized = normalizePayload(payload);
  const code = normalized.code || slugifyCode(normalized.name);

  if (!code) {
    throw new AppError('Category code could not be generated', 422);
  }

  const existing = await shipmentCategoryModel.findByCode(code);

  if (existing) {
    throw new AppError('Shipment category already exists', 409);
  }

  try {
    return await shipmentCategoryModel.createCategory({
      ...normalized,
      code,
      isActive: normalized.isActive !== undefined ? normalized.isActive : true,
    });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      throw new AppError('Shipment category already exists', 409);
    }

    throw error;
  }
};

const updateAdminCategory = async (categoryId, payload) => {
  const category = await shipmentCategoryModel.findById(categoryId);

  if (!category) {
    throw new AppError('Shipment category not found', 404);
  }

  return shipmentCategoryModel.updateCategory(categoryId, normalizePayload(payload));
};

const deleteAdminCategory = async (categoryId) => {
  const category = await shipmentCategoryModel.findById(categoryId);

  if (!category) {
    throw new AppError('Shipment category not found', 404);
  }

  await shipmentCategoryModel.softDeleteCategory(categoryId);

  return {
    deleted: true,
  };
};

module.exports = {
  createAdminCategory,
  deleteAdminCategory,
  getAdminCategory,
  listAdminCategories,
  listCustomerCategories,
  updateAdminCategory,
};
