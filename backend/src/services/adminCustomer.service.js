const { getPool } = require('../config/database');
const adminCustomerModel = require('../models/adminCustomer.model');
const auditLogModel = require('../models/auditLog.model');
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

const buildStatusNote = ({ action, adminUser, reason }) => {
  const actor = adminUser?.email || adminUser?.username || `user:${adminUser?.id}`;
  const note = `${new Date().toISOString()} - ${action} by ${actor}`;

  return reason ? `${note}. Reason: ${reason}` : note;
};

const assertCustomer = (customer) => {
  if (!customer) {
    throw new AppError('Customer was not found', 404);
  }
};

const writeAuditLog = async (
  { adminUser, action, entityId, oldValues = null, newValues = null, requestMeta = {} },
  connection,
) => {
  if (!adminUser?.id) {
    return;
  }

  await auditLogModel.createAuditLog(
    {
      actorUserId: adminUser.id,
      action,
      entityType: 'customer',
      entityId,
      oldValues,
      newValues,
      ...requestMeta,
    },
    connection,
  );
};

const listCustomers = async (filters = {}) => {
  const pagination = normalizePagination(filters);
  const { rows, total } = await adminCustomerModel.listCustomers({
    filters,
    pagination,
  });

  return {
    customers: rows,
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
            title: 'No customers found',
            message: 'Try changing search, status, location, or date filters.',
          }
        : null,
  };
};

const getCustomerDetails = async (customerId) => {
  const customer = await adminCustomerModel.findById(customerId);
  assertCustomer(customer);

  const recentShipments = await adminCustomerModel.listRecentShipments({
    customerId: customer.id,
    limit: 5,
  });

  return {
    customer,
    recentShipments,
  };
};

const activateCustomer = async ({ customerId, adminUser, requestMeta = {} }) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const existingCustomer = await adminCustomerModel.findById(
      customerId,
      connection,
    );
    assertCustomer(existingCustomer);

    const customer = await adminCustomerModel.updateStatus(
      {
        customerId,
        accountStatus: 'active',
        userStatus: 'active',
        notes: buildStatusNote({
          action: 'Activated',
          adminUser,
        }),
      },
      connection,
    );

    await writeAuditLog(
      {
        adminUser,
        action: 'customer.activated',
        entityId: customer.id,
        oldValues: existingCustomer,
        newValues: customer,
        requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      customer,
      status: 'active',
      message: 'Customer account activated successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const deactivateCustomer = async ({
  customerId,
  adminUser,
  reason,
  requestMeta = {},
}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const existingCustomer = await adminCustomerModel.findById(
      customerId,
      connection,
    );
    assertCustomer(existingCustomer);

    const customer = await adminCustomerModel.updateStatus(
      {
        customerId,
        accountStatus: 'inactive',
        userStatus: 'inactive',
        notes: buildStatusNote({
          action: 'Deactivated',
          adminUser,
          reason,
        }),
      },
      connection,
    );

    await writeAuditLog(
      {
        adminUser,
        action: 'customer.deactivated',
        entityId: customer.id,
        oldValues: existingCustomer,
        newValues: {
          ...customer,
          reason: reason || null,
        },
        requestMeta,
      },
      connection,
    );

    await connection.commit();

    return {
      customer,
      status: 'inactive',
      message: 'Customer account deactivated successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  activateCustomer,
  deactivateCustomer,
  getCustomerDetails,
  listCustomers,
};
