const { getPool } = require('../config/database');
const customerFeedbackModel = require('../models/customerFeedback.model');
const customerShipmentReadModel = require('../models/customerShipmentRead.model');
const customerProfileService = require('./customerProfile.service');
const AppError = require('../utils/appError');

const normalizePagination = ({ page = 1, limit = 10 } = {}) => {
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(50, Math.max(1, Number(limit) || 10));

  return {
    page: safePage,
    limit: safeLimit,
    offset: (safePage - 1) * safeLimit,
  };
};

const generateCode = (prefix) => {
  const datePart = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const randomPart = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `${prefix}-${datePart}-${Date.now().toString().slice(-6)}${randomPart}`;
};

const submitFeedback = async (userId, payload) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const customer = await customerProfileService.getActiveCustomerProfile(
      userId,
      connection,
    );
    const shipment = await customerShipmentReadModel.findShipmentDetail(
      {
        customerId: customer.id,
        shipmentId: payload.shipmentId,
      },
      connection,
    );

    if (!shipment) {
      throw new AppError('Shipment was not found for this customer', 404);
    }

    const existing = await customerFeedbackModel.findByShipmentForCustomer(
      {
        customerId: customer.id,
        shipmentId: shipment.id,
      },
      connection,
    );

    if (existing) {
      throw new AppError('Feedback has already been submitted for this shipment', 409);
    }

    const feedback = await customerFeedbackModel.createFeedback(
      {
        feedbackCode: generateCode('FDB'),
        customerId: customer.id,
        shipmentId: shipment.id,
        rating: payload.rating,
        experienceTags: payload.experienceTags || [],
        comments: payload.comments,
        wouldRecommend: payload.wouldRecommend !== false,
      },
      connection,
    );

    await connection.commit();

    return {
      feedback,
      thankYou: {
        title: 'Thank you for your feedback',
        message: 'Your delivery experience has been recorded.',
      },
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const listFeedback = async (userId, filters = {}) => {
  const customer = await customerProfileService.getActiveCustomerProfile(userId);
  const pagination = normalizePagination(filters);
  const list = await customerFeedbackModel.listForCustomer({
    customerId: customer.id,
    filters,
    pagination,
  });

  return {
    feedback: list.rows,
    meta: {
      total: list.total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(list.total / pagination.limit),
      hasMore: pagination.page * pagination.limit < list.total,
    },
    emptyState:
      list.rows.length === 0
        ? {
            title: 'No feedback submitted',
            message: 'Completed delivery feedback will appear here.',
          }
        : null,
  };
};

module.exports = {
  listFeedback,
  submitFeedback,
};
