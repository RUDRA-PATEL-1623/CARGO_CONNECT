const { getPool } = require('../config/database');
const { NOTIFICATION_TYPES } = require('../constants/notification.constants');
const customerShipmentReadModel = require('../models/customerShipmentRead.model');
const customerSupportModel = require('../models/customerSupport.model');
const notificationService = require('./notification.service');
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

const assertOwnShipment = async ({ customerId, shipmentId }, connection = null) => {
  if (!shipmentId) {
    return null;
  }

  const shipment = await customerShipmentReadModel.findShipmentDetail(
    {
      customerId,
      shipmentId,
    },
    connection,
  );

  if (!shipment) {
    throw new AppError('Shipment was not found for this customer', 404);
  }

  return shipment;
};

const createIssue = async (userId, payload) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const customer = await customerProfileService.getActiveCustomerProfile(
      userId,
      connection,
    );
    const shipment = await assertOwnShipment(
      {
        customerId: customer.id,
        shipmentId: payload.shipmentId,
      },
      connection,
    );
    const subject = payload.subject ||
      `${payload.issueType.replace(/_/g, ' ')} support request`;
    const issue = await customerSupportModel.createIssue(
      {
        issueCode: generateCode('SUP'),
        customerId: customer.id,
        shipmentId: shipment?.id || null,
        issueType: payload.issueType,
        priority: payload.priority || 'medium',
        subject,
        description: payload.description,
        attachmentUrl: payload.attachmentUrl,
        issueStatus: 'open',
      },
      connection,
    );

    await notificationService.createForAdmins(
      {
        shipmentId: shipment?.id || null,
        notificationType: NOTIFICATION_TYPES.SYSTEM,
        title: 'New customer support issue',
        message: `Support issue ${issue.issueCode} was raised by a customer.`,
        metadata: {
          issueId: issue.id,
          issueCode: issue.issueCode,
          priority: issue.priority,
          issueType: issue.issueType,
        },
      },
      connection,
    );

    await connection.commit();

    return {
      issue,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const listIssues = async (userId, filters = {}) => {
  const customer = await customerProfileService.getActiveCustomerProfile(userId);
  const pagination = normalizePagination(filters);
  const list = await customerSupportModel.listForCustomer({
    customerId: customer.id,
    filters,
    pagination,
  });

  return {
    issues: list.rows,
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
            title: 'No support issues',
            message: 'Raised shipment, payment, and delivery issues will appear here.',
          }
        : null,
  };
};

module.exports = {
  createIssue,
  listIssues,
};
