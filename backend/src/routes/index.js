const express = require('express');

const env = require('../config/env');
const { successResponse } = require('../utils/response');
const adminAssignmentRoutes = require('./adminAssignment.routes');
const adminCustomerRoutes = require('./adminCustomer.routes');
const adminDashboardRoutes = require('./adminDashboard.routes');
const adminDriverRoutes = require('./adminDriver.routes');
const adminInvoiceRoutes = require('./adminInvoice.routes');
const adminNotificationRoutes = require('./adminNotification.routes');
const adminPaymentRoutes = require('./adminPayment.routes');
const adminProfileRoutes = require('./adminProfile.routes');
const adminReportRoutes = require('./adminReport.routes');
const adminRequestRoutes = require('./adminRequest.routes');
const adminSettingsRoutes = require('./adminSettings.routes');
const adminShipmentRoutes = require('./adminShipment.routes');
const adminVehicleRoutes = require('./adminVehicle.routes');
const customerAuthRoutes = require('./customerAuth.routes');
const customerCheckoutRoutes = require('./customerCheckout.routes');
const customerFeedbackRoutes = require('./customerFeedback.routes');
const customerNotificationRoutes = require('./customerNotification.routes');
const customerProfileRoutes = require('./customerProfile.routes');
const customerShipmentRoutes = require('./customerShipment.routes');
const customerShipmentReadRoutes = require('./customerShipmentRead.routes');
const customerSupportRoutes = require('./customerSupport.routes');
const driverRequestRoutes = require('./driverRequest.routes');
const driverNotificationRoutes = require('./driverNotification.routes');
const driverProfileRoutes = require('./driverProfile.routes');
const driverTripRoutes = require('./driverTrip.routes');
const healthRoutes = require('./health.routes');
const shipmentCategoryRoutes = require('./shipmentCategory.routes');

const router = express.Router();

router.get('/', (req, res) => {
  return successResponse({
    res,
    message: 'CargoConnect API route registry',
    data: {
      version: 'v1',
      environment: env.nodeEnv,
      endpoints: [
        {
          method: 'GET',
          path: `${env.apiPrefix}`,
          description: 'Route registry and API foundation status.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/health`,
          description: 'API process health check.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/health/db`,
          description: 'MySQL connectivity health check.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/customer/register`,
          description: 'Register a customer and send email OTP.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/customer/login`,
          description: 'Login a verified active customer.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/customer/verify-otp`,
          description: 'Verify customer registration OTP.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/customer/resend-otp`,
          description: 'Resend customer registration OTP.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/driver/login`,
          description: 'Login an admin-created driver account.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/driver/profile`,
          description: 'Fetch authenticated driver profile and active assignment count.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/availability`,
          description: 'Update authenticated driver availability when no active assignment exists.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/driver/logout`,
          description: 'Stateless driver logout acknowledgement; discard JWT on the client.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/driver/trips`,
          description: 'List trips assigned to the authenticated driver.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/driver/trips/history`,
          description: 'List completed, rejected, and cancelled trips for the authenticated driver.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/driver/trips/:assignmentId`,
          description: 'Fetch one driver-owned trip assignment.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/driver/trips/:assignmentId/proofs/pickup`,
          description: 'Driver upload pickup proof image metadata.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/driver/trips/:assignmentId/proofs/delivery`,
          description: 'Driver upload delivery proof image metadata.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/trips/:assignmentId/accept`,
          description: 'Driver accept a newly assigned trip.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/trips/:assignmentId/reject`,
          description: 'Driver reject a newly assigned trip with reason.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/trips/:assignmentId/start`,
          description: 'Driver start an accepted trip.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/trips/:assignmentId/pickup-completed`,
          description: 'Driver mark pickup completed after trip start.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/trips/:assignmentId/in-transit`,
          description: 'Driver mark pickup-completed trip as in transit.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/trips/:assignmentId/status-update`,
          description: 'Driver record an in-transit ETA, delay, or issue update.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/trips/:assignmentId/delivery-completed`,
          description: 'Driver mark in-transit trip as delivered.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/trips/:assignmentId/complete`,
          description: 'Driver complete a delivered trip.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/driver/reports`,
          description: 'Driver list own emergency and breakdown reports.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/driver/reports/emergency`,
          description: 'Driver submit an emergency report with optional attachment.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/driver/reports/breakdown`,
          description: 'Driver submit a breakdown report with optional attachment.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/driver/fuel-requests`,
          description: 'Driver list own fuel requests.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/driver/fuel-requests`,
          description: 'Driver submit a fuel request.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/driver/fuel-requests/:fuelRequestId/bill`,
          description: 'Driver upload a fuel bill for a pending fuel request.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/driver/notifications`,
          description: 'Driver list own notifications with read/type filters.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/notifications/:notificationId/read`,
          description: 'Driver mark one notification as read.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/driver/notifications/read-all`,
          description: 'Driver mark all notifications as read.',
        },
        {
          method: 'DELETE',
          path: `${env.apiPrefix}/driver/notifications/clear`,
          description: 'Driver soft clear all notifications.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/admin/login`,
          description: 'Login an admin or dispatcher account.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/profile`,
          description: 'Fetch authenticated admin or dispatcher profile.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/admin/logout`,
          description: 'Stateless admin logout acknowledgement; discard JWT on the client.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/forgot-password`,
          description: 'Generate a password reset OTP.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/verify-reset-otp`,
          description: 'Verify reset OTP and receive a reset token.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/create-new-password`,
          description: 'Create a new password with a reset token.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/reset-password`,
          description: 'Reset password directly with a password reset OTP.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/auth/change-password`,
          description: 'Change password for the authenticated user.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/shipment-categories`,
          description: 'Customer-facing active shipment category list.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/profile`,
          description: 'Fetch authenticated customer profile.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/customer/profile`,
          description: 'Update authenticated customer profile.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/shipment-categories`,
          description: 'Admin shipment category list.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/admin/shipment-categories`,
          description: 'Admin create shipment category.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/shipment-categories/:categoryId`,
          description: 'Admin shipment category detail.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/shipment-categories/:categoryId`,
          description: 'Admin update shipment category.',
        },
        {
          method: 'DELETE',
          path: `${env.apiPrefix}/admin/shipment-categories/:categoryId`,
          description: 'Admin soft delete shipment category.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/dashboard/metrics`,
          description: 'Admin dashboard shipment, driver, vehicle, revenue, and activity metrics.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/dashboard/recent-activity`,
          description: 'Admin dashboard recent activity table data.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/shipments`,
          description: 'Admin shipment report with date, status, and category filters.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/shipments/export?format=csv|pdf`,
          description: 'Export shipment report as CSV or PDF.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/drivers`,
          description: 'Admin driver report with date, status, and category filters.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/drivers/export?format=csv|pdf`,
          description: 'Export driver report as CSV or PDF.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/vehicles`,
          description: 'Admin vehicle report with date, status, and category filters.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/vehicles/export?format=csv|pdf`,
          description: 'Export vehicle report as CSV or PDF.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/payments`,
          description: 'Admin payment report with date, status, and category filters.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/payments/export?format=csv|pdf`,
          description: 'Export payment report as CSV or PDF.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/invoices`,
          description: 'Admin invoice report with date, status, and category filters.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/invoices/export?format=csv|pdf`,
          description: 'Export invoice report as CSV or PDF.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/payments`,
          description: 'Admin payment list with search, method, status, date, category filters, and pagination.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/payments/:paymentId`,
          description: 'Admin payment detail with shipment, customer, and invoice context.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/invoices`,
          description: 'Admin invoice list with search, status, date, category filters, and pagination.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/invoices/:invoiceId`,
          description: 'Admin invoice preview with shipment, customer, and payment context.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/invoices/:invoiceId/download`,
          description: 'Download locally generated admin invoice PDF.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/settings`,
          description: 'Fetch grouped admin settings from the database.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/settings`,
          description: 'Update admin settings with audit logging.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/customers`,
          description: 'Admin customer list with search, filters, and pagination.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/customers/:customerId`,
          description: 'Admin customer details with recent shipment summary.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/customers/:customerId/activate`,
          description: 'Admin activate customer profile and login.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/customers/:customerId/deactivate`,
          description: 'Admin deactivate customer profile and login.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/drivers`,
          description: 'Admin driver list with search, status, availability, license filters, and pagination.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/admin/drivers`,
          description: 'Admin create driver profile and linked login credentials.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/drivers/:driverId`,
          description: 'Admin driver details with vehicle and recent assignment summary.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/drivers/:driverId`,
          description: 'Admin update driver profile and login fields.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/drivers/:driverId/activate`,
          description: 'Admin activate driver profile and login.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/drivers/:driverId/deactivate`,
          description: 'Admin deactivate driver profile and login.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/vehicles`,
          description: 'Admin vehicle list with search, type, fuel, service, insurance, availability filters, and pagination.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports`,
          description: 'Admin list emergency and breakdown reports.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/reports/:reportId`,
          description: 'Admin fetch emergency or breakdown report details.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/reports/:reportId/status`,
          description: 'Admin update emergency or breakdown report status.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/fuel-requests`,
          description: 'Admin list fuel requests.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/fuel-requests/:fuelRequestId`,
          description: 'Admin fetch fuel request details.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/fuel-requests/:fuelRequestId/approve`,
          description: 'Admin approve a pending fuel request.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/fuel-requests/:fuelRequestId/reject`,
          description: 'Admin reject a pending fuel request.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/fuel-requests/:fuelRequestId/mark-paid`,
          description: 'Admin mark an approved fuel request as paid.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/notifications`,
          description: 'Admin list own notifications with read/type filters.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/admin/notifications`,
          description: 'Admin create a manual notification for one user or role.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/notifications/:notificationId/read`,
          description: 'Admin mark one notification as read.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/notifications/read-all`,
          description: 'Admin mark all notifications as read.',
        },
        {
          method: 'DELETE',
          path: `${env.apiPrefix}/admin/notifications/clear`,
          description: 'Admin soft clear all notifications.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/admin/vehicles`,
          description: 'Admin create vehicle record.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/vehicles/:vehicleId`,
          description: 'Admin vehicle details with assigned driver and recent assignment summary.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/vehicles/:vehicleId`,
          description: 'Admin update vehicle registration, capacity, type, expiry, service, and availability fields.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/vehicles/:vehicleId/activate`,
          description: 'Admin activate vehicle for dispatch.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/vehicles/:vehicleId/deactivate`,
          description: 'Admin deactivate vehicle and clear driver assignment.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/shipments`,
          description: 'Admin shipment list with search, status, payment, category, date, and assignment filters.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/admin/shipments/:shipmentId`,
          description: 'Admin shipment details with payment, invoice, assignments, proofs, and trip logs.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/shipments/:shipmentId/approve`,
          description: 'Admin approve a paid pending shipment.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/shipments/:shipmentId/reject`,
          description: 'Admin reject a pending shipment with audit log.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/shipments/:shipmentId/cancel`,
          description: 'Admin cancel a non-terminal shipment with audit log.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/shipments/:shipmentId/reassign`,
          description: 'Admin assign or reassign shipment driver and vehicle with audit log.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/admin/assignments/validate-conflicts`,
          description: 'Admin validate driver and vehicle assignment conflicts.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/admin/assignments`,
          description: 'Admin assign driver and vehicle to an approved shipment.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/admin/assignments/:assignmentId/replace`,
          description: 'Admin replace driver and vehicle on an active assignment.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/customer/shipments/estimate`,
          description: 'Calculate customer shipment price estimate.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/customer/shipments`,
          description: 'Create customer shipment request.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/shipments/:shipmentId/summary`,
          description: 'Fetch customer shipment summary.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/shipments`,
          description: 'Fetch customer shipment history with filters and pagination.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/shipments/:shipmentId`,
          description: 'Fetch customer-owned shipment details.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/shipments/:shipmentId/timeline`,
          description: 'Fetch customer-owned shipment status timeline.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/shipments/:shipmentId/tracking`,
          description: 'Fetch customer-owned shipment tracking summary.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/shipments/:shipmentId/proofs`,
          description: 'Fetch customer-owned shipment proof uploads.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/shipments/:shipmentId/proofs/:proofId`,
          description: 'Fetch one customer-owned shipment proof upload.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/customer/shipments/:shipmentId/place-order`,
          description: 'Place customer order after mock payment and generate invoice.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/shipments/:shipmentId/checkout`,
          description: 'Fetch checkout price breakdown and payment readiness.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/customer/shipments/:shipmentId/checkout/mock-payment`,
          description: 'Confirm mock payment, create payment, and generate invoice.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/invoices/:invoiceId`,
          description: 'Fetch customer invoice preview.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/invoices/:invoiceId/download`,
          description: 'Generate and download customer invoice PDF.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/notifications`,
          description: 'Fetch customer notifications with read/type filters.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/customer/notifications/:notificationId/read`,
          description: 'Mark one customer notification as read.',
        },
        {
          method: 'PATCH',
          path: `${env.apiPrefix}/customer/notifications/read-all`,
          description: 'Mark all customer notifications as read.',
        },
        {
          method: 'DELETE',
          path: `${env.apiPrefix}/customer/notifications/clear`,
          description: 'Soft clear all customer notifications.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/support/issues`,
          description: 'List support issues created by the authenticated customer.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/customer/support/issues`,
          description: 'Create a support issue for the authenticated customer.',
        },
        {
          method: 'GET',
          path: `${env.apiPrefix}/customer/feedback`,
          description: 'List feedback submitted by the authenticated customer.',
        },
        {
          method: 'POST',
          path: `${env.apiPrefix}/customer/feedback`,
          description: 'Submit shipment feedback for the authenticated customer.',
        },
      ],
    },
  });
});

router.use('/auth', customerAuthRoutes);
router.use('/health', healthRoutes);
router.use('/admin/assignments', adminAssignmentRoutes);
router.use('/admin/customers', adminCustomerRoutes);
router.use('/admin/dashboard', adminDashboardRoutes);
router.use('/admin/drivers', adminDriverRoutes);
router.use('/admin/invoices', adminInvoiceRoutes);
router.use('/admin', adminNotificationRoutes);
router.use('/admin/payments', adminPaymentRoutes);
router.use('/admin', adminProfileRoutes);
router.use('/admin', adminReportRoutes);
router.use('/admin', adminRequestRoutes);
router.use('/admin/settings', adminSettingsRoutes);
router.use('/admin/shipments', adminShipmentRoutes);
router.use('/admin/vehicles', adminVehicleRoutes);
router.use('/', shipmentCategoryRoutes);
router.use('/customer', customerShipmentRoutes);
router.use('/customer', customerProfileRoutes);
router.use('/customer', customerCheckoutRoutes);
router.use('/customer', customerShipmentReadRoutes);
router.use('/customer', customerNotificationRoutes);
router.use('/customer', customerSupportRoutes);
router.use('/customer', customerFeedbackRoutes);
router.use('/driver', driverProfileRoutes);
router.use('/driver', driverTripRoutes);
router.use('/driver', driverNotificationRoutes);
router.use('/driver', driverRequestRoutes);

module.exports = router;
