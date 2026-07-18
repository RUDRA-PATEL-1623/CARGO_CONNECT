const { getPool } = require('../config/database');
const adminRequestModel = require('../models/adminRequest.model');
const auditLogModel = require('../models/auditLog.model');
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

const createAudit = async (
  { action, entityType, entityId, actorUserId, requestMeta, oldValues, newValues },
  connection,
) => {
  await auditLogModel.createAuditLog(
    {
      actorUserId,
      action,
      entityType,
      entityId,
      oldValues,
      newValues,
      ipAddress: requestMeta?.ipAddress || null,
      userAgent: requestMeta?.userAgent || null,
    },
    connection,
  );
};

const listReports = async (filters = {}) => {
  const pagination = normalizePagination(filters);
  const { rows, total } = await adminRequestModel.listReports({
    filters,
    pagination,
  });

  return {
    reports: rows,
    meta: {
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(total / pagination.limit),
      hasMore: pagination.page * pagination.limit < total,
    },
  };
};

const getReportDetails = async (reportId) => {
  const report = await adminRequestModel.findReportById(reportId);

  if (!report) {
    throw new AppError('Report was not found', 404);
  }

  return {
    report,
  };
};

const updateReportStatus = async ({
  reportId,
  reportStatus,
  resolutionNotes,
  actorUserId,
  requestMeta,
}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const existing = await adminRequestModel.findReportById(reportId, connection);

    if (!existing) {
      throw new AppError('Report was not found', 404);
    }

    if (existing.reportStatus === 'closed') {
      throw new AppError('Closed reports cannot be updated', 409);
    }

    const report = await adminRequestModel.updateReportStatus(
      {
        reportId,
        reportStatus,
        actorUserId,
        resolutionNotes,
      },
      connection,
    );

    await createAudit(
      {
        action: 'admin.report.status_updated',
        entityType: 'emergency_report',
        entityId: report.id,
        actorUserId,
        requestMeta,
        oldValues: {
          reportStatus: existing.reportStatus,
          resolutionNotes: existing.resolutionNotes,
        },
        newValues: {
          reportStatus: report.reportStatus,
          resolutionNotes: report.resolutionNotes,
        },
      },
      connection,
    );

    await connection.commit();

    return {
      report,
      message: 'Report status updated successfully.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const listFuelRequests = async (filters = {}) => {
  const pagination = normalizePagination(filters);
  const { rows, total } = await adminRequestModel.listFuelRequests({
    filters,
    pagination,
  });

  return {
    fuelRequests: rows,
    meta: {
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(total / pagination.limit),
      hasMore: pagination.page * pagination.limit < total,
    },
  };
};

const getFuelRequestDetails = async (fuelRequestId) => {
  const fuelRequest = await adminRequestModel.findFuelRequestById(fuelRequestId);

  if (!fuelRequest) {
    throw new AppError('Fuel request was not found', 404);
  }

  return {
    fuelRequest,
  };
};

const updateFuelRequestStatus = async ({
  fuelRequestId,
  requestStatus,
  reviewNotes,
  actorUserId,
  requestMeta,
}) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const existing = await adminRequestModel.findFuelRequestById(
      fuelRequestId,
      connection,
    );

    if (!existing) {
      throw new AppError('Fuel request was not found', 404);
    }

    if (requestStatus === 'approved' && existing.requestStatus !== 'pending') {
      throw new AppError('Only pending fuel requests can be approved', 409, {
        requestStatus: existing.requestStatus,
      });
    }

    if (requestStatus === 'rejected' && existing.requestStatus !== 'pending') {
      throw new AppError('Only pending fuel requests can be rejected', 409, {
        requestStatus: existing.requestStatus,
      });
    }

    if (requestStatus === 'paid' && existing.requestStatus !== 'approved') {
      throw new AppError('Only approved fuel requests can be marked paid', 409, {
        requestStatus: existing.requestStatus,
      });
    }

    if (requestStatus === 'approved' && !existing.billFileUrl) {
      throw new AppError('Fuel bill upload is required before approval', 422);
    }

    const fuelRequest = await adminRequestModel.updateFuelStatus(
      {
        fuelRequestId,
        requestStatus,
        actorUserId,
        reviewNotes,
      },
      connection,
    );

    await createAudit(
      {
        action: `admin.fuel_request.${requestStatus}`,
        entityType: 'fuel_request',
        entityId: fuelRequest.id,
        actorUserId,
        requestMeta,
        oldValues: {
          requestStatus: existing.requestStatus,
          reviewNotes: existing.reviewNotes,
        },
        newValues: {
          requestStatus: fuelRequest.requestStatus,
          reviewNotes: fuelRequest.reviewNotes,
        },
      },
      connection,
    );

    await connection.commit();

    return {
      fuelRequest,
      message: `Fuel request marked ${requestStatus}.`,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const approveFuelRequest = (payload) => updateFuelRequestStatus({
  ...payload,
  requestStatus: 'approved',
});

const rejectFuelRequest = (payload) => updateFuelRequestStatus({
  ...payload,
  requestStatus: 'rejected',
});

const markFuelRequestPaid = (payload) => updateFuelRequestStatus({
  ...payload,
  requestStatus: 'paid',
});

module.exports = {
  approveFuelRequest,
  getFuelRequestDetails,
  getReportDetails,
  listFuelRequests,
  listReports,
  markFuelRequestPaid,
  rejectFuelRequest,
  updateReportStatus,
};
