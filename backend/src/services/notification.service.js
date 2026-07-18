const { USER_ROLES } = require('../constants/auth.constants');
const {
  NOTIFICATION_TYPES,
  allowedNotificationTypes,
} = require('../constants/notification.constants');
const notificationModel = require('../models/notification.model');
const userModel = require('../models/user.model');
const AppError = require('../utils/appError');

const normalizePagination = ({ page = 1, limit = 20 } = {}) => {
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(50, Math.max(1, Number(limit) || 20));

  return {
    page: safePage,
    limit: safeLimit,
    offset: (safePage - 1) * safeLimit,
  };
};

const createNotification = async (payload, connection = null) => {
  if (!payload?.userId) {
    return null;
  }

  return notificationModel.createNotification(payload, connection);
};

const createNotifications = async (notifications, connection = null) => {
  return notificationModel.createNotifications(notifications, connection);
};

const createForRole = async (
  {
    role,
    notificationType,
    title,
    message,
    shipmentId = null,
    channel = undefined,
    metadata = null,
  },
  connection = null,
) => {
  const userIds = await notificationModel.listActiveUserIdsByRole(role, connection);

  return createNotifications(
    userIds.map((userId) => ({
      userId,
      shipmentId,
      notificationType,
      title,
      message,
      channel,
      metadata,
    })),
    connection,
  );
};

const createForAdmins = async (payload, connection = null) => createForRole(
  {
    ...payload,
    role: USER_ROLES.ADMIN,
  },
  connection,
);

const listUserNotifications = async (userId, filters = {}) => {
  const pagination = normalizePagination(filters);
  const [list, unreadCount] = await Promise.all([
    notificationModel.listNotifications({
      filters: {
        ...filters,
        userId,
      },
      pagination,
    }),
    notificationModel.countUnreadForUser(userId),
  ]);

  return {
    notifications: list.rows,
    unreadCount,
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
            title: 'No notifications',
            message: 'Booking, trip, delivery, and support updates will appear here.',
          }
        : null,
  };
};

const markNotificationRead = async (userId, notificationId) => {
  const notification = await notificationModel.markAsRead({
    userId,
    notificationId,
  });

  if (!notification) {
    throw new AppError('Notification was not found', 404);
  }

  return notification;
};

const markAllNotificationsRead = async (userId) => {
  const updatedCount = await notificationModel.markAllAsRead(userId);
  const unreadCount = await notificationModel.countUnreadForUser(userId);

  return {
    updatedCount,
    unreadCount,
  };
};

const clearNotifications = async (userId) => {
  const clearedCount = await notificationModel.clearAllForUser(userId);

  return {
    clearedCount,
  };
};

const createManualNotification = async ({ actorUserId, payload }) => {
  if (!allowedNotificationTypes.includes(payload.notificationType)) {
    throw new AppError('Notification type is not supported', 422);
  }

  if (!payload.userId && !payload.targetRole) {
    throw new AppError('Either userId or targetRole is required', 422);
  }

  if (payload.userId) {
    const user = await userModel.findById(payload.userId);

    if (!user) {
      throw new AppError('Notification recipient was not found', 404);
    }

    const notification = await createNotification({
      userId: payload.userId,
      shipmentId: payload.shipmentId,
      notificationType: payload.notificationType,
      title: payload.title,
      message: payload.message,
      channel: payload.channel,
      metadata: {
        ...(payload.metadata || {}),
        createdByUserId: actorUserId,
      },
    });

    return {
      notifications: [notification],
    };
  }

  const notifications = await createForRole({
    role: payload.targetRole,
    shipmentId: payload.shipmentId,
    notificationType: payload.notificationType,
    title: payload.title,
    message: payload.message,
    channel: payload.channel,
    metadata: {
      ...(payload.metadata || {}),
      createdByUserId: actorUserId,
    },
  });

  return {
    notifications,
  };
};

const notifyBookingCreated = async ({ customerUserId, shipment }, connection = null) => {
  await createNotifications(
    [
      {
        userId: customerUserId,
        shipmentId: shipment.id,
        notificationType: NOTIFICATION_TYPES.BOOKING_CONFIRMED,
        title: 'Booking confirmed',
        message: `Your booking ${shipment.shipmentCode} is pending admin approval.`,
        metadata: {
          shipmentStatus: shipment.shipmentStatus,
          paymentStatus: shipment.paymentStatus,
        },
      },
    ],
    connection,
  );

  await createForAdmins(
    {
      shipmentId: shipment.id,
      notificationType: NOTIFICATION_TYPES.BOOKING_CONFIRMED,
      title: 'New shipment booking',
      message: `New booking ${shipment.shipmentCode} is ready for review.`,
      metadata: {
        shipmentStatus: shipment.shipmentStatus,
        customerUserId,
      },
    },
    connection,
  );
};

const notifyShipmentApproved = async ({ customerUserId, shipment }, connection = null) => {
  await createNotification(
    {
      userId: customerUserId,
      shipmentId: shipment.id,
      notificationType: NOTIFICATION_TYPES.SHIPMENT_APPROVED,
      title: 'Shipment approved',
      message: `Shipment ${shipment.shipmentCode} has been approved for assignment.`,
      metadata: {
        shipmentStatus: shipment.shipmentStatus,
      },
    },
    connection,
  );
};

const notifyDriverAssigned = async (
  { customerUserId, driverUserId, shipment, assignment },
  connection = null,
) => {
  await createNotifications(
    [
      {
        userId: customerUserId,
        shipmentId: shipment.id,
        notificationType: NOTIFICATION_TYPES.DRIVER_ASSIGNED,
        title: 'Driver assigned',
        message: `A driver has been assigned to shipment ${shipment.shipmentCode}.`,
        metadata: {
          assignmentId: assignment.id,
          assignmentCode: assignment.assignmentCode,
          driverId: assignment.driverId,
        },
      },
      {
        userId: driverUserId,
        shipmentId: shipment.id,
        notificationType: NOTIFICATION_TYPES.DRIVER_ASSIGNED,
        title: 'New trip assigned',
        message: `Shipment ${shipment.shipmentCode} has been assigned to you.`,
        metadata: {
          assignmentId: assignment.id,
          assignmentCode: assignment.assignmentCode,
        },
      },
    ],
    connection,
  );
};

const notifyTripAccepted = async ({ customerUserId, shipment, assignment }, connection = null) => {
  await createNotification(
    {
      userId: customerUserId,
      shipmentId: shipment.id,
      notificationType: NOTIFICATION_TYPES.DRIVER_ACCEPTED,
      title: 'Driver accepted trip',
      message: `Your driver accepted shipment ${shipment.shipmentCode}.`,
      metadata: {
        assignmentId: assignment.id,
      },
    },
    connection,
  );
};

const notifyTripRejected = async ({ customerUserId, shipment, assignment, reason }, connection = null) => {
  await createNotification(
    {
      userId: customerUserId,
      shipmentId: shipment.id,
      notificationType: NOTIFICATION_TYPES.DRIVER_REJECTED,
      title: 'Driver rejected trip',
      message: `The assigned driver rejected shipment ${shipment.shipmentCode}. Dispatch will reassign it.`,
      metadata: {
        assignmentId: assignment.id,
        reason,
      },
    },
    connection,
  );

  await createForAdmins(
    {
      shipmentId: shipment.id,
      notificationType: NOTIFICATION_TYPES.DRIVER_REJECTED,
      title: 'Driver rejected assignment',
      message: `Assignment ${assignment.assignmentCode} was rejected by the driver.`,
      metadata: {
        assignmentId: assignment.id,
        reason,
      },
    },
    connection,
  );
};

const notifyShipmentStatus = async (
  { customerUserId, shipment, assignment, notificationType, title, message },
  connection = null,
) => {
  await createNotification(
    {
      userId: customerUserId,
      shipmentId: shipment.id,
      notificationType,
      title,
      message,
      metadata: {
        assignmentId: assignment.id,
        shipmentStatus: shipment.shipmentStatus,
        assignmentStatus: assignment.assignmentStatus,
      },
    },
    connection,
  );
};

const notifyShipmentCancelled = async (
  { customerUserId, driverUserIds = [], shipment, reason },
  connection = null,
) => {
  const isRejected = shipment.shipmentStatus === 'rejected';
  const actionLabel = isRejected ? 'rejected' : 'cancelled';
  const recipients = [
    customerUserId,
    ...driverUserIds,
  ].filter(Boolean);

  await createNotifications(
    recipients.map((userId) => ({
      userId,
      shipmentId: shipment.id,
      notificationType: NOTIFICATION_TYPES.CANCELLED,
      title: isRejected ? 'Shipment rejected' : 'Shipment cancelled',
      message: `Shipment ${shipment.shipmentCode} has been ${actionLabel}.`,
      metadata: {
        reason,
        shipmentStatus: shipment.shipmentStatus,
      },
    })),
    connection,
  );
};

const notifyEmergencyReported = async ({ report }, connection = null) => {
  await createForAdmins(
    {
      shipmentId: report.shipmentId || null,
      notificationType: NOTIFICATION_TYPES.EMERGENCY_REPORTED,
      title: 'Driver emergency reported',
      message: `${report.driverName || 'A driver'} reported ${report.reportType} severity ${report.severity}.`,
      metadata: {
        reportId: report.id,
        reportCode: report.reportCode,
        reportType: report.reportType,
        issueType: report.issueType,
        severity: report.severity,
        driverId: report.driverId,
      },
    },
    connection,
  );
};

module.exports = {
  createForAdmins,
  createForRole,
  createManualNotification,
  createNotification,
  createNotifications,
  clearNotifications,
  listUserNotifications,
  markAllNotificationsRead,
  markNotificationRead,
  notifyBookingCreated,
  notifyDriverAssigned,
  notifyEmergencyReported,
  notifyShipmentApproved,
  notifyShipmentCancelled,
  notifyShipmentStatus,
  notifyTripAccepted,
  notifyTripRejected,
};
