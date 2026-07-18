const adminPaymentModel = require('../models/adminPayment.model');
const AppError = require('../utils/appError');

const normalizePagination = ({ page = 1, limit = 10 } = {}) => {
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(100, Math.max(1, Number(limit) || 10));

  return {
    page: safePage,
    limit: safeLimit,
    offset: (safePage - 1) * safeLimit,
  };
};

const listPayments = async (filters = {}) => {
  const pagination = normalizePagination(filters);
  const { rows, total } = await adminPaymentModel.listPayments({
    filters,
    pagination,
  });

  return {
    payments: rows,
    meta: {
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(total / pagination.limit),
      hasMore: pagination.page * pagination.limit < total,
    },
    emptyState:
      rows.length === 0
        ? {
            title: 'No payments found',
            message: 'Try changing search, method, status, date, or category filters.',
          }
        : null,
  };
};

const getPaymentDetails = async (paymentId) => {
  const payment = await adminPaymentModel.findById(paymentId);

  if (!payment) {
    throw new AppError('Payment was not found', 404);
  }

  return {
    payment,
  };
};

module.exports = {
  getPaymentDetails,
  listPayments,
};
