const adminDashboardModel = require('../models/adminDashboard.model');

const ACTIVE_DELIVERY_STATUSES = [
  'approved',
  'assigned',
  'accepted',
  'pickup_completed',
  'in_transit',
];

const normalizeActivityLimit = (value) => {
  const parsed = Number(value || 10);
  return Math.min(20, Math.max(1, Number.isFinite(parsed) ? parsed : 10));
};

const getDashboardMetrics = async (filters = {}) => {
  const activityLimit = normalizeActivityLimit(filters.activityLimit);

  const [
    shipments,
    drivers,
    vehicleUtilization,
    revenueSummary,
    recentActivity,
  ] = await Promise.all([
    adminDashboardModel.getShipmentMetrics(filters),
    adminDashboardModel.getDriverMetrics(),
    adminDashboardModel.getVehicleUtilization(),
    adminDashboardModel.getRevenueSummary(filters),
    adminDashboardModel.getRecentActivity({ limit: activityLimit }),
  ]);

  return {
    filters: {
      dateFrom: filters.dateFrom || null,
      dateTo: filters.dateTo || null,
      activityLimit,
    },
    cards: {
      totalShipments: shipments.totalShipments,
      pendingShipments: shipments.pendingShipments,
      activeDeliveries: shipments.activeDeliveries,
      deliveredShipments: shipments.deliveredShipments,
      cancelledShipments: shipments.cancelledShipments,
      availableDrivers: drivers.availableDrivers,
      busyDrivers: drivers.busyDrivers,
    },
    shipments,
    drivers,
    vehicleUtilization,
    revenueSummary,
    recentActivity,
    definitions: {
      activeDeliveryStatuses: ACTIVE_DELIVERY_STATUSES,
      deliveredShipmentStatuses: ['delivered', 'completed'],
    },
  };
};

const getRecentActivity = async (filters = {}) => {
  const limit = normalizeActivityLimit(filters.limit);
  const recentActivity = await adminDashboardModel.getRecentActivity({ limit });

  return {
    recentActivity,
    meta: {
      limit,
    },
  };
};

module.exports = {
  getDashboardMetrics,
  getRecentActivity,
};
