import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../constants/mock_admin_data.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'dio_client.dart';

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService(ref.watch(dioClientProvider));
});

class AdminApiService {
  const AdminApiService(this._dio);

  final Dio _dio;

  Future<AdminDashboardData> fetchDashboard() async {
    final data = await _getMap(
      '/admin/dashboard/metrics',
      query: {'activityLimit': 10},
    );
    return _mapDashboard(data);
  }

  Future<List<AdminShipmentManagementMock>> fetchShipments({
    String? search,
    String? status,
    int limit = 50,
  }) async {
    final data = await _getMap(
      '/admin/shipments',
      query: {
        'page': 1,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status,
      },
    );
    return _list(data, 'shipments').map(_mapShipmentRow).toList();
  }

  Future<AdminShipmentDetailsData> fetchShipmentDetails(
    String shipmentId,
  ) async {
    final backendId =
        int.tryParse(shipmentId) ?? await _resolveShipmentId(shipmentId);
    final data = await _getMap('/admin/shipments/$backendId');
    return _mapShipmentDetails(data);
  }

  Future<AdminShipmentManagementMock> approveShipment({
    required AdminShipmentManagementMock shipment,
    String? notes,
  }) async {
    final data = await _patchMap(
      '/admin/shipments/${_backendId(shipment)}/approve',
      data: {'notes': notes ?? ''},
    );
    return _mapShipmentRow(_map(data['shipment']));
  }

  Future<AdminShipmentManagementMock> rejectShipment({
    required AdminShipmentManagementMock shipment,
    required String reason,
  }) async {
    final data = await _patchMap(
      '/admin/shipments/${_backendId(shipment)}/reject',
      data: {'reason': reason},
    );
    return _mapShipmentRow(_map(data['shipment']));
  }

  Future<AdminShipmentManagementMock> cancelShipment({
    required AdminShipmentManagementMock shipment,
    required String reason,
  }) async {
    final data = await _patchMap(
      '/admin/shipments/${_backendId(shipment)}/cancel',
      data: {'reason': reason},
    );
    return _mapShipmentRow(_map(data['shipment']));
  }

  Future<AdminAssignmentData> fetchAssignmentData({
    String? initialShipmentId,
  }) async {
    final results = await Future.wait([
      fetchShipments(limit: 50),
      fetchDrivers(limit: 50),
      fetchVehicles(limit: 50),
    ]);

    return AdminAssignmentData(
      shipments: results[0] as List<AdminShipmentManagementMock>,
      drivers: (results[1] as List<AdminDriverManagementMock>)
          .map(_driverToAssignment)
          .toList(),
      vehicles: (results[2] as List<AdminVehicleManagementMock>)
          .map(_vehicleToAssignment)
          .toList(),
    );
  }

  Future<AdminAssignmentValidation> validateAssignment({
    required AdminShipmentManagementMock shipment,
    required AdminDriverAssignmentMock driver,
    required AdminVehicleAssignmentMock vehicle,
  }) async {
    final data = await _postMap(
      '/admin/assignments/validate-conflicts',
      data: {
        'shipmentId': _backendId(shipment),
        'driverId': _backendId(driver),
        'vehicleId': _backendId(vehicle),
      },
    );
    return AdminAssignmentValidation.fromJson(data);
  }

  Future<void> assignShipment({
    required AdminShipmentManagementMock shipment,
    required AdminDriverAssignmentMock driver,
    required AdminVehicleAssignmentMock vehicle,
    String? notes,
  }) async {
    final payload = {
      'driverId': _backendId(driver),
      'vehicleId': _backendId(vehicle),
      'notes': notes ?? 'Assigned from admin web panel',
    };

    final assignmentId = shipment.assignmentBackendId;
    if (assignmentId != null && assignmentId > 0) {
      await _patchMap(
        '/admin/assignments/$assignmentId/replace',
        data: payload,
      );
      return;
    }

    await _postMap(
      '/admin/assignments',
      data: {'shipmentId': _backendId(shipment), ...payload},
    );
  }

  Future<AdminProfileData> fetchProfile() async {
    final data = await _getMap('/admin/profile');
    return AdminProfileData.fromJson(data);
  }

  Future<AdminSettingsData> fetchSettings() async {
    final data = await _getMap('/admin/settings');
    return AdminSettingsData.fromJson(data);
  }

  Future<AdminSettingsData> saveSettings(Map<String, dynamic> payload) async {
    final data = await _patchMap('/admin/settings', data: payload);
    return AdminSettingsData.fromJson(data);
  }

  Future<AdminNotificationData> fetchNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    final data = await _getMap(
      '/admin/notifications',
      query: {'page': page, 'limit': limit},
    );
    return AdminNotificationData.fromJson(data);
  }

  Future<AdminNotificationItem> markNotificationRead(
    AdminNotificationItem notification,
  ) async {
    final data = await _patchMap(
      '/admin/notifications/${notification.id}/read',
    );
    return AdminNotificationItem.fromJson(_map(data['notification']));
  }

  Future<int> markAllNotificationsRead() async {
    final data = await _patchMap('/admin/notifications/read-all');
    return _asNum(data['updatedCount']).toInt();
  }

  Future<int> clearNotifications() async {
    final data = await _deleteMap('/admin/notifications/clear');
    return _asNum(data['clearedCount']).toInt();
  }

  Future<List<AdminDriverManagementMock>> fetchDrivers({int limit = 50}) async {
    final data = await _getMap(
      '/admin/drivers',
      query: {'page': 1, 'limit': limit},
    );
    return _list(data, 'drivers').map(_mapDriverRow).toList();
  }

  Future<AdminDriverManagementMock> createDriver(
    Map<String, dynamic> payload,
  ) async {
    final data = await _postMap('/admin/drivers', data: payload);
    final driver = _mapDriverRow(_map(data['driver']));
    final credentials = _map(data['loginCredentials']);
    return driver.copyWith(
      temporaryPassword:
          credentials['temporaryPassword']?.toString() ??
          credentials['generatedPassword']?.toString() ??
          driver.temporaryPassword,
    );
  }

  Future<AdminDriverManagementMock> updateDriver(
    AdminDriverManagementMock driver,
    Map<String, dynamic> payload,
  ) async {
    final data = await _patchMap(
      '/admin/drivers/${_backendId(driver)}',
      data: payload,
    );
    return _mapDriverRow(_map(data['driver']));
  }

  Future<AdminDriverManagementMock> activateDriver(
    AdminDriverManagementMock driver,
  ) async {
    final data = await _patchMap(
      '/admin/drivers/${_backendId(driver)}/activate',
    );
    return _mapDriverRow(_map(data['driver']));
  }

  Future<AdminDriverManagementMock> deactivateDriver(
    AdminDriverManagementMock driver,
  ) async {
    final data = await _patchMap(
      '/admin/drivers/${_backendId(driver)}/deactivate',
    );
    return _mapDriverRow(_map(data['driver']));
  }

  Future<List<AdminVehicleManagementMock>> fetchVehicles({
    int limit = 50,
  }) async {
    final data = await _getMap(
      '/admin/vehicles',
      query: {'page': 1, 'limit': limit},
    );
    return _list(data, 'vehicles').map(_mapVehicleRow).toList();
  }

  Future<AdminVehicleManagementMock> createVehicle(
    Map<String, dynamic> payload,
  ) async {
    final data = await _postMap('/admin/vehicles', data: payload);
    return _mapVehicleRow(_map(data['vehicle']));
  }

  Future<AdminVehicleManagementMock> updateVehicle(
    AdminVehicleManagementMock vehicle,
    Map<String, dynamic> payload,
  ) async {
    final data = await _patchMap(
      '/admin/vehicles/${_backendId(vehicle)}',
      data: payload,
    );
    return _mapVehicleRow(_map(data['vehicle']));
  }

  Future<AdminVehicleManagementMock> activateVehicle(
    AdminVehicleManagementMock vehicle,
  ) async {
    final data = await _patchMap(
      '/admin/vehicles/${_backendId(vehicle)}/activate',
    );
    return _mapVehicleRow(_map(data['vehicle']));
  }

  Future<AdminVehicleManagementMock> deactivateVehicle(
    AdminVehicleManagementMock vehicle,
  ) async {
    final data = await _patchMap(
      '/admin/vehicles/${_backendId(vehicle)}/deactivate',
    );
    return _mapVehicleRow(_map(data['vehicle']));
  }

  Future<List<AdminCustomerManagementMock>> fetchCustomers({
    int limit = 50,
  }) async {
    final data = await _getMap(
      '/admin/customers',
      query: {'page': 1, 'limit': limit},
    );
    return _list(data, 'customers').map(_mapCustomerRow).toList();
  }

  Future<AdminCustomerManagementMock> activateCustomer(
    AdminCustomerManagementMock customer,
  ) async {
    final data = await _patchMap(
      '/admin/customers/${_backendId(customer)}/activate',
    );
    return _mapCustomerRow(_map(data['customer']));
  }

  Future<AdminCustomerManagementMock> deactivateCustomer(
    AdminCustomerManagementMock customer,
  ) async {
    final data = await _patchMap(
      '/admin/customers/${_backendId(customer)}/deactivate',
      data: {'reason': 'Deactivated from admin web panel'},
    );
    return _mapCustomerRow(_map(data['customer']));
  }

  Future<List<AdminPaymentManagementMock>> fetchPayments({
    int limit = 100,
  }) async {
    final data = await _getMap(
      '/admin/payments',
      query: {'page': 1, 'limit': limit},
    );
    return _list(data, 'payments').map(_mapPaymentRow).toList();
  }

  Future<List<AdminInvoiceManagementMock>> fetchInvoices({
    int limit = 100,
  }) async {
    final data = await _getMap(
      '/admin/invoices',
      query: {'page': 1, 'limit': limit},
    );
    return _list(data, 'invoices').map(_mapInvoiceRow).toList();
  }

  Future<AdminPaymentManagementMock> fetchPaymentDetails(
    AdminPaymentManagementMock payment,
  ) async {
    final data = await _getMap('/admin/payments/${_backendId(payment)}');
    return _mapPaymentRow(_map(data['payment']));
  }

  Future<AdminInvoiceManagementMock> fetchInvoiceDetails(
    AdminInvoiceManagementMock invoice,
  ) async {
    final data = await _getMap('/admin/invoices/${_backendId(invoice)}');
    final preview = <String, dynamic>{
      ..._map(data['shipment']),
      ..._map(data['payment']),
      ..._map(data['invoice']),
    };
    return _mapInvoiceRow(preview);
  }

  Future<int> downloadInvoicePdf(AdminInvoiceManagementMock invoice) async {
    try {
      final response = await _dio.get<List<int>>(
        '/admin/invoices/${_backendId(invoice)}/download',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const <int>[]).length;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<AdminReportData> fetchReport(
    String reportType, {
    Map<String, dynamic>? query,
  }) async {
    final data = await _getMap(
      '/admin/reports/$reportType',
      query: {'page': 1, 'limit': 100, ...?query},
    );
    return AdminReportData.fromJson(data);
  }

  Future<int> exportReport(
    String reportType,
    String format, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        '/admin/reports/$reportType/export',
        queryParameters: {'format': format.toLowerCase(), ...?query},
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const <int>[]).length;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<AdminReportsOverviewData> fetchReportsOverview({
    Map<String, dynamic>? query,
  }) async {
    final reports = await Future.wait<AdminReportData>([
      fetchReport('shipments', query: query),
      fetchReport('drivers', query: query),
      fetchReport('vehicles', query: query),
      fetchReport('payments', query: query),
    ]);
    return AdminReportsOverviewData.fromReports(
      shipments: AdminShipmentReportUiData.fromReport(reports[0]),
      drivers: AdminDriverReportUiData.fromReport(reports[1]),
      vehicles: AdminVehicleReportUiData.fromReport(reports[2]),
      payments: AdminPaymentReportUiData.fromReport(reports[3]),
    );
  }

  Future<AdminShipmentReportUiData> fetchShipmentReportUi({
    Map<String, dynamic>? query,
  }) async {
    return AdminShipmentReportUiData.fromReport(
      await fetchReport('shipments', query: query),
    );
  }

  Future<AdminDriverReportUiData> fetchDriverReportUi({
    Map<String, dynamic>? query,
  }) async {
    return AdminDriverReportUiData.fromReport(
      await fetchReport('drivers', query: query),
    );
  }

  Future<AdminVehicleReportUiData> fetchVehicleReportUi({
    Map<String, dynamic>? query,
  }) async {
    return AdminVehicleReportUiData.fromReport(
      await fetchReport('vehicles', query: query),
    );
  }

  Future<AdminPaymentReportUiData> fetchPaymentReportUi({
    Map<String, dynamic>? query,
  }) async {
    return AdminPaymentReportUiData.fromReport(
      await fetchReport('payments', query: query),
    );
  }

  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      return _dataMap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<Map<String, dynamic>> _postMap(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return _dataMap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<Map<String, dynamic>> _patchMap(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(path, data: data);
      return _dataMap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<Map<String, dynamic>> _deleteMap(String path) async {
    try {
      final response = await _dio.delete<dynamic>(path);
      return _dataMap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Map<String, dynamic> _dataMap(Object? body) {
    return ApiResponse.fromJson(body).dataAsMap();
  }

  Future<int> _resolveShipmentId(String displayId) async {
    final data = await _getMap(
      '/admin/shipments',
      query: {'search': displayId, 'page': 1, 'limit': 1},
    );
    final shipments = _list(data, 'shipments');
    if (shipments.isEmpty) {
      throw ApiException(message: 'Shipment $displayId was not found.');
    }
    return _asInt(shipments.first['id']) ?? 0;
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.stats,
    required this.shipmentTrend,
    required this.revenueBreakdown,
    required this.vehicleUtilization,
    required this.recentActivity,
    required this.revenueAmount,
    required this.revenueDelta,
    required this.utilizationPercent,
    required this.driverCapacity,
    required this.shipmentQueue,
    required this.collections,
  });

  final List<AdminStatMock> stats;
  final List<AdminChartPointMock> shipmentTrend;
  final List<AdminChartPointMock> revenueBreakdown;
  final List<AdminChartPointMock> vehicleUtilization;
  final List<AdminRecentActivityMock> recentActivity;
  final String revenueAmount;
  final String revenueDelta;
  final double utilizationPercent;
  final String driverCapacity;
  final String shipmentQueue;
  final String collections;
}

class AdminShipmentDetailsData {
  const AdminShipmentDetailsData({
    required this.shipment,
    required this.detail,
    required this.proofs,
    required this.tripLogs,
  });

  final AdminShipmentManagementMock shipment;
  final AdminShipmentDetailMock detail;
  final List<Map<String, dynamic>> proofs;
  final List<Map<String, dynamic>> tripLogs;
}

class AdminAssignmentData {
  const AdminAssignmentData({
    required this.shipments,
    required this.drivers,
    required this.vehicles,
  });

  final List<AdminShipmentManagementMock> shipments;
  final List<AdminDriverAssignmentMock> drivers;
  final List<AdminVehicleAssignmentMock> vehicles;
}

class AdminAssignmentValidation {
  const AdminAssignmentValidation({
    required this.canAssign,
    required this.messages,
  });

  final bool canAssign;
  final List<String> messages;

  factory AdminAssignmentValidation.fromJson(Map<String, dynamic> json) {
    final conflicts = _list(json, 'conflicts');
    return AdminAssignmentValidation(
      canAssign: json['canAssign'] == true,
      messages: conflicts
          .map((conflict) => conflict['message']?.toString() ?? 'Conflict')
          .toList(),
    );
  }
}

class AdminReportData {
  const AdminReportData({
    required this.title,
    required this.rows,
    required this.summary,
    required this.meta,
  });

  final String title;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> meta;

  factory AdminReportData.fromJson(Map<String, dynamic> json) {
    return AdminReportData(
      title: json['title']?.toString() ?? 'Report',
      rows: _list(json, 'rows'),
      summary: _map(json['summary']),
      meta: _map(json['meta']),
    );
  }
}

class AdminProfileData {
  const AdminProfileData({
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.status,
    required this.lastLogin,
    required this.permissions,
  });

  final String name;
  final String role;
  final String email;
  final String phone;
  final String status;
  final String lastLogin;
  final Map<String, dynamic> permissions;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'AD';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String get displayRole => _statusLabel(role);

  factory AdminProfileData.fromJson(Map<String, dynamic> json) {
    final profile = _map(json['profile']);
    return AdminProfileData(
      name: _text(profile['name'], fallback: 'CargoConnect Admin'),
      role: _text(profile['role'], fallback: 'admin'),
      email: _text(profile['email'], fallback: 'admin@cargoconnect.local'),
      phone: _text(profile['phone'], fallback: 'Not provided'),
      status: _statusLabel(profile['status'] ?? profile['accountStatus']),
      lastLogin: _relativeOrDate(profile['lastLoginAt']),
      permissions: _map(json['permissions']),
    );
  }
}

class AdminSettingsData {
  const AdminSettingsData({required this.groupedSettings});

  final Map<String, Map<String, dynamic>> groupedSettings;

  Object? value(String group, String key) => groupedSettings[group]?[key];

  factory AdminSettingsData.fromJson(Map<String, dynamic> json) {
    final grouped = _map(json['groupedSettings']);
    return AdminSettingsData(
      groupedSettings: {
        for (final entry in grouped.entries) entry.key: _map(entry.value),
      },
    );
  }
}

class AdminNotificationData {
  const AdminNotificationData({
    required this.notifications,
    required this.unreadCount,
  });

  final List<AdminNotificationItem> notifications;
  final int unreadCount;

  factory AdminNotificationData.fromJson(Map<String, dynamic> json) {
    return AdminNotificationData(
      notifications: _list(
        json,
        'notifications',
      ).map(AdminNotificationItem.fromJson).toList(),
      unreadCount: _asNum(json['unreadCount']).toInt(),
    );
  }
}

class AdminNotificationItem {
  const AdminNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.time,
    required this.isRead,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final String status;
  final String time;
  final bool isRead;

  factory AdminNotificationItem.fromJson(Map<String, dynamic> json) {
    final type = _text(json['notificationType'] ?? json['type']);
    return AdminNotificationItem(
      id: _asInt(json['id']) ?? 0,
      title: _text(json['title'], fallback: 'Admin notification'),
      message: _text(json['message'], fallback: 'Operational update.'),
      type: type,
      status: _notificationStatus(json),
      time: _relativeOrDate(json['createdAt']),
      isRead:
          json['isRead'] == true ||
          json['readAt'] != null ||
          json['read'] == true,
    );
  }
}

class AdminReportsOverviewData {
  const AdminReportsOverviewData({
    required this.reportCards,
    required this.shipmentPoints,
    required this.driverPoints,
    required this.vehiclePoints,
    required this.paymentPoints,
  });

  final List<AdminReportCardMock> reportCards;
  final List<AdminChartPointMock> shipmentPoints;
  final List<AdminChartPointMock> driverPoints;
  final List<AdminChartPointMock> vehiclePoints;
  final List<AdminChartPointMock> paymentPoints;

  factory AdminReportsOverviewData.fromReports({
    required AdminShipmentReportUiData shipments,
    required AdminDriverReportUiData drivers,
    required AdminVehicleReportUiData vehicles,
    required AdminPaymentReportUiData payments,
  }) {
    return AdminReportsOverviewData(
      reportCards: [
        AdminReportCardMock(
          title: 'Shipment report',
          metric: '${shipments.totalBookings}',
          delta: '${shipments.totalDelivered} delivered',
          description:
              'Date, status, and category shipment aggregates from the database.',
          status: shipments.totalCancelled == 0 ? 'Healthy' : 'Watch',
          icon: Icons.inventory_2_outlined,
          accentColor: AppColors.primaryBlue,
          isPositive: shipments.totalCancelled == 0,
        ),
        AdminReportCardMock(
          title: 'Driver report',
          metric: '${drivers.completedTrips}',
          delta: '${drivers.acceptanceRate.toStringAsFixed(1)}% acceptance',
          description:
              'Driver trip performance, availability, and exception counts.',
          status: drivers.emergencyCount == 0 ? 'Operational' : 'Watch',
          icon: Icons.badge_outlined,
          accentColor: AppColors.success,
          isPositive: drivers.emergencyCount == 0,
        ),
        AdminReportCardMock(
          title: 'Vehicle report',
          metric: '${vehicles.averageUtilization}%',
          delta: '${vehicles.serviceDueSoon} service due soon',
          description:
              'Fleet utilization, active assignments, and service exposure.',
          status: vehicles.serviceDueSoon == 0 ? 'Healthy' : 'Watch service',
          icon: Icons.local_shipping_outlined,
          accentColor: AppColors.warning,
          isPositive: vehicles.serviceDueSoon == 0,
        ),
        AdminReportCardMock(
          title: 'Payment report',
          metric: payments.totalRevenue,
          delta: '${payments.totalTransactions} transactions',
          description:
              'Revenue, payment method mix, pending, and refunded exposure.',
          status: 'Finance',
          icon: Icons.payments_outlined,
          accentColor: AppColors.info,
          isPositive: true,
        ),
      ],
      shipmentPoints: [
        for (final row in shipments.statusRows)
          AdminChartPointMock(label: row.status, value: row.count.toDouble()),
      ],
      driverPoints: [
        for (final row in drivers.rows)
          AdminChartPointMock(
            label: _shortLabel(row.name),
            value: row.completedTrips.toDouble(),
          ),
      ],
      vehiclePoints: [
        for (final row in vehicles.rows)
          AdminChartPointMock(
            label: _shortLabel(row.vehicleNumber),
            value: row.utilization.toDouble(),
          ),
      ],
      paymentPoints: [
        for (final row in payments.statusRows)
          AdminChartPointMock(label: row.status, value: row.count.toDouble()),
      ],
    );
  }
}

class AdminShipmentReportUiData {
  const AdminShipmentReportUiData({
    required this.dateRows,
    required this.statusRows,
    required this.categoryRows,
  });

  final List<AdminShipmentDateReportMock> dateRows;
  final List<AdminShipmentStatusReportMock> statusRows;
  final List<AdminShipmentCategoryReportMock> categoryRows;

  bool get isEmpty =>
      dateRows.isEmpty && statusRows.isEmpty && categoryRows.isEmpty;

  int get totalBookings =>
      dateRows.fold(0, (total, row) => total + row.bookings);
  int get totalDelivered =>
      statusRows
          .where((row) => row.status == 'Delivered')
          .fold(0, (total, row) => total + row.count) +
      statusRows
          .where((row) => row.status == 'Completed')
          .fold(0, (total, row) => total + row.count);
  int get totalCancelled => statusRows
      .where((row) => row.status == 'Cancelled')
      .fold(0, (total, row) => total + row.count);

  factory AdminShipmentReportUiData.fromReport(AdminReportData report) {
    final dateWise = _list(report.summary, 'dateWise');
    final statusWise = _list(report.summary, 'statusWise');
    final categoryWise = _list(report.summary, 'categoryWise');
    final totalByStatus = statusWise.fold<num>(
      0,
      (total, row) => total + _asNum(row['shipmentCount']),
    );
    return AdminShipmentReportUiData(
      dateRows: [
        for (final row in dateWise)
          AdminShipmentDateReportMock(
            date: _dateOnlyLabel(row['reportDate']),
            bookings: _asNum(row['shipmentCount']).toInt(),
            approved: 0,
            inTransit: 0,
            delivered: 0,
            cancelled: 0,
            revenue: _money(row['estimatedAmount']),
          ),
      ],
      statusRows: [
        for (final row in statusWise)
          AdminShipmentStatusReportMock(
            status: _statusLabel(row['status']),
            count: _asNum(row['shipmentCount']).toInt(),
            share: _percent(_asNum(row['shipmentCount']), totalByStatus),
            revenue: _money(row['estimatedAmount']),
            sla: 'Database aggregate',
          ),
      ],
      categoryRows: [
        for (final row in categoryWise)
          AdminShipmentCategoryReportMock(
            category: _text(row['categoryName'], fallback: 'Uncategorized'),
            shipments: _asNum(row['shipmentCount']).toInt(),
            averageWeight: 'From shipments',
            revenue: _money(row['estimatedAmount']),
            topVehicle: _statusLabel(row['categoryCode']),
          ),
      ],
    );
  }
}

class AdminDriverReportUiData {
  const AdminDriverReportUiData({required this.rows});

  final List<AdminDriverReportMock> rows;

  bool get isEmpty => rows.isEmpty;
  int get completedTrips =>
      rows.fold(0, (total, row) => total + row.completedTrips);
  int get delays => rows.fold(0, (total, row) => total + row.delays);
  int get emergencyCount =>
      rows.fold(0, (total, row) => total + row.emergencyCount);
  double get acceptanceRate => rows.isEmpty
      ? 0
      : rows.fold<double>(0, (total, row) => total + row.acceptanceRate) /
            rows.length;
  double get performanceScore => rows.isEmpty
      ? 0
      : rows.fold<double>(0, (total, row) => total + row.performanceScore) /
            rows.length;

  factory AdminDriverReportUiData.fromReport(AdminReportData report) {
    return AdminDriverReportUiData(
      rows: [for (final row in report.rows) _driverReportRow(row)],
    );
  }
}

class AdminVehicleReportUiData {
  const AdminVehicleReportUiData({
    required this.rows,
    required this.assignments,
    required this.breakdowns,
  });

  final List<AdminVehicleReportMock> rows;
  final List<AdminVehicleAssignmentHistoryReportMock> assignments;
  final List<AdminVehicleBreakdownReportMock> breakdowns;

  bool get isEmpty => rows.isEmpty;
  int get averageUtilization {
    if (rows.isEmpty) {
      return 0;
    }
    return (rows.fold<int>(0, (total, row) => total + row.utilization) /
            rows.length)
        .round();
  }

  int get serviceDueSoon =>
      rows.where((row) => _daysUntil(row.serviceDue) <= 14).length;
  int get busyVehicles =>
      rows.where((row) => row.availability == 'Busy').length;
  int get breakdownCount =>
      rows.fold(0, (total, row) => total + row.breakdownCount);

  factory AdminVehicleReportUiData.fromReport(AdminReportData report) {
    final rows = [for (final row in report.rows) _vehicleReportRow(row)];
    return AdminVehicleReportUiData(
      rows: rows,
      assignments: [
        for (final row in rows)
          if (row.assignedTrip != null)
            AdminVehicleAssignmentHistoryReportMock(
              date: _dateOnlyLabel(DateTime.now()),
              vehicleNumber: row.vehicleNumber,
              tripId: row.assignedTrip!,
              driver: row.assignedDriver,
              route: 'Active assignment',
              status: row.availability,
              duration: 'Current',
            ),
      ],
      breakdowns: const [],
    );
  }
}

class AdminPaymentReportUiData {
  const AdminPaymentReportUiData({
    required this.revenueRows,
    required this.methodRows,
    required this.statusRows,
  });

  final List<AdminPaymentRevenueReportMock> revenueRows;
  final List<AdminPaymentMethodReportMock> methodRows;
  final List<AdminPaymentStatusReportMock> statusRows;

  bool get isEmpty =>
      revenueRows.isEmpty && methodRows.isEmpty && statusRows.isEmpty;
  int get totalTransactions =>
      revenueRows.fold(0, (total, row) => total + row.transactions);
  String get totalRevenue => _money(
    statusRows
        .where((row) => row.status == 'Paid')
        .fold<num>(0, (total, row) => total + _moneyToNum(row.amount)),
  );

  AdminPaymentStatusReportMock statusRow(String status) {
    return statusRows.firstWhere(
      (row) => row.status == status,
      orElse: () => AdminPaymentStatusReportMock(
        status: status,
        count: 0,
        amount: _money(0),
        share: '0%',
        action: 'No records',
      ),
    );
  }

  factory AdminPaymentReportUiData.fromReport(AdminReportData report) {
    final dateWise = _list(report.summary, 'dateWise');
    final statusWise = _list(report.summary, 'statusWise');
    final methodWise = _list(report.summary, 'methodWise');
    final totalByStatus = statusWise.fold<num>(
      0,
      (total, row) => total + _asNum(row['paymentCount']),
    );
    return AdminPaymentReportUiData(
      revenueRows: [
        for (final row in dateWise)
          AdminPaymentRevenueReportMock(
            date: _dateOnlyLabel(row['reportDate']),
            paidRevenue: _money(row['totalAmount']),
            pendingAmount: _money(0),
            refundedAmount: _money(0),
            transactions: _asNum(row['paymentCount']).toInt(),
          ),
      ],
      methodRows: [
        for (final row in methodWise)
          AdminPaymentMethodReportMock(
            method: _statusLabel(row['paymentMethod']),
            transactions: _asNum(row['paymentCount']).toInt(),
            revenue: _money(row['totalAmount']),
            pendingAmount: _money(0),
            successRate: 'Backend aggregate',
            settlementNote: 'Loaded from payments table',
          ),
      ],
      statusRows: [
        for (final row in statusWise)
          AdminPaymentStatusReportMock(
            status: _statusLabel(row['status']),
            count: _asNum(row['paymentCount']).toInt(),
            amount: _money(row['totalAmount']),
            share: _percent(_asNum(row['paymentCount']), totalByStatus),
            action: 'Review in payment management',
          ),
      ],
    );
  }
}

AdminDashboardData _mapDashboard(Map<String, dynamic> data) {
  final cards = _map(data['cards']);
  final drivers = _map(data['drivers']);
  final revenue = _map(data['revenueSummary']);
  final vehicles = _map(data['vehicleUtilization']);
  final recentActivity = _list(data, 'recentActivity');
  final paidAmount = _asNum(revenue['paidAmount']);
  final pendingAmount = _asNum(revenue['pendingAmount']);
  final refundedAmount = _asNum(revenue['refundedAmount']);

  return AdminDashboardData(
    stats: [
      AdminStatMock(
        label: 'Total shipments',
        value: _count(cards['totalShipments']),
        delta: 'All booked shipments',
        icon: Icons.inventory_2_outlined,
        isPositive: true,
        accentColor: AppColors.primaryBlue,
      ),
      AdminStatMock(
        label: 'Pending',
        value: _count(cards['pendingShipments']),
        delta: 'Need admin review',
        icon: Icons.pending_actions_outlined,
        isPositive: _asNum(cards['pendingShipments']) == 0,
        accentColor: AppColors.warning,
      ),
      AdminStatMock(
        label: 'Active deliveries',
        value: _count(cards['activeDeliveries']),
        delta: 'Approved through in transit',
        icon: Icons.local_shipping_outlined,
        isPositive: true,
        accentColor: AppColors.info,
      ),
      AdminStatMock(
        label: 'Delivered',
        value: _count(cards['deliveredShipments']),
        delta: 'Delivered or completed',
        icon: Icons.task_alt_rounded,
        isPositive: true,
        accentColor: AppColors.success,
      ),
      AdminStatMock(
        label: 'Cancelled',
        value: _count(cards['cancelledShipments']),
        delta: 'Cancelled shipment count',
        icon: Icons.cancel_outlined,
        isPositive: _asNum(cards['cancelledShipments']) == 0,
        accentColor: AppColors.danger,
      ),
      AdminStatMock(
        label: 'Available drivers',
        value: _count(cards['availableDrivers']),
        delta: '${_count(cards['busyDrivers'])} busy drivers',
        icon: Icons.badge_outlined,
        isPositive: _asNum(cards['availableDrivers']) > 0,
        accentColor: AppColors.primaryBlue,
      ),
    ],
    shipmentTrend: [
      AdminChartPointMock(
        label: 'Pending',
        value: _asNum(cards['pendingShipments']).toDouble(),
      ),
      AdminChartPointMock(
        label: 'Active',
        value: _asNum(cards['activeDeliveries']).toDouble(),
      ),
      AdminChartPointMock(
        label: 'Done',
        value: _asNum(cards['deliveredShipments']).toDouble(),
      ),
      AdminChartPointMock(
        label: 'Cancel',
        value: _asNum(cards['cancelledShipments']).toDouble(),
      ),
    ],
    revenueBreakdown: [
      for (final row in _list(revenue, 'methodBreakdown'))
        AdminChartPointMock(
          label: _shortLabel(_label(row['paymentMethod'])),
          value: _asNum(row['paidAmount']).toDouble(),
        ),
    ],
    vehicleUtilization: [
      AdminChartPointMock(
        label: 'Available',
        value: _asNum(vehicles['availableVehicles']).toDouble(),
      ),
      AdminChartPointMock(
        label: 'Assigned',
        value: _asNum(vehicles['assignedVehicles']).toDouble(),
      ),
      AdminChartPointMock(
        label: 'Service',
        value: _asNum(vehicles['maintenanceVehicles']).toDouble(),
      ),
      AdminChartPointMock(
        label: 'Inactive',
        value: _asNum(vehicles['inactiveVehicles']).toDouble(),
      ),
    ],
    recentActivity: [
      for (final item in recentActivity)
        AdminRecentActivityMock(
          time: _relativeOrDate(item['occurredAt']),
          activity: item['title']?.toString() ?? 'Operational update',
          reference: item['resourceCode']?.toString() ?? '-',
          owner: item['actorName']?.toString() ?? 'System',
          status: _statusLabel(item['status']),
          amount: '-',
        ),
    ],
    revenueAmount: _money(paidAmount),
    revenueDelta: '${_count(revenue['paidPayments'])} paid payments',
    utilizationPercent: _asNum(vehicles['utilizationPercent']).toDouble() / 100,
    driverCapacity:
        '${_count(drivers['availableDrivers'])} available / ${_count(drivers['busyDrivers'])} busy',
    shipmentQueue: '${_count(cards['pendingShipments'])} pending approvals',
    collections:
        '${_money(pendingAmount)} pending, ${_money(refundedAmount)} refunded',
  );
}

AdminShipmentDetailsData _mapShipmentDetails(Map<String, dynamic> data) {
  final shipment = _map(data['shipment']);
  final payment = _map(data['payment']);
  final invoice = _map(data['invoice']);
  final currentAssignment = _map(data['currentAssignment']);
  final summary = _mapShipmentRow({
    ...shipment,
    if (payment.isNotEmpty) 'paymentTotalAmount': payment['totalAmount'],
    if (invoice.isNotEmpty) 'invoiceNumber': invoice['invoiceNumber'],
    if (currentAssignment.isNotEmpty) ...{
      'latestAssignmentId': currentAssignment['id'],
      'latestAssignmentCode': currentAssignment['assignmentCode'],
      'latestAssignmentStatus': currentAssignment['assignmentStatus'],
      'latestDriverName': currentAssignment['driverName'],
      'latestVehicleNumber': currentAssignment['vehicleNumber'],
      'latestVehicleRegistrationNumber':
          currentAssignment['vehicleRegistrationNumber'],
    },
  });

  final dimensions = [
    shipment['packageLengthCm'],
    shipment['packageWidthCm'],
    shipment['packageHeightCm'],
  ].where((value) => value != null).join(' x ');

  return AdminShipmentDetailsData(
    shipment: summary,
    detail: AdminShipmentDetailMock(
      id: summary.id,
      backendId: _asInt(shipment['id']),
      customerName: _text(shipment['customerName'], fallback: 'Customer'),
      customerEmail: _text(shipment['customerEmail'], fallback: '-'),
      customerPhone: _text(shipment['customerPhone'], fallback: '-'),
      receiverName: _text(shipment['receiverName'], fallback: '-'),
      receiverPhone: _text(shipment['receiverPhone'], fallback: '-'),
      pickupAddress: _address(shipment, 'pickup'),
      deliveryAddress: _address(shipment, 'delivery'),
      packageType: _text(shipment['packageType'], fallback: 'Package'),
      weight: '${_asNum(shipment['packageWeightKg'])} kg',
      dimensions: dimensions.isEmpty ? 'Not specified' : '$dimensions cm',
      paymentMethod: _statusLabel(payment['paymentMethod']),
      paymentStatus: _statusLabel(
        payment['paymentStatus'] ?? shipment['paymentStatus'],
      ),
      invoiceNumber: _text(invoice['invoiceNumber'], fallback: '-'),
      invoiceStatus: _statusLabel(invoice['invoiceStatus']),
      adminNotes: _text(shipment['deliveryNotes'], fallback: 'No admin notes.'),
    ),
    proofs: _list(data, 'proofs'),
    tripLogs: _list(data, 'tripLogs'),
  );
}

AdminShipmentManagementMock _mapShipmentRow(Map<String, dynamic> row) {
  final pickupDate = _parseDate(
    row['scheduledPickupAt'] ?? row['pickupDateTime'],
  );
  final assignmentCode = _text(row['latestAssignmentCode'], fallback: '');
  final latestDriver = _text(row['latestDriverName'], fallback: '');
  final driver = latestDriver.isNotEmpty
      ? latestDriver
      : assignmentCode.isEmpty
      ? 'Unassigned'
      : assignmentCode;
  final latestVehicle = _text(
    row['latestVehicleNumber'] ?? row['latestVehicleRegistrationNumber'],
    fallback: '',
  );
  final amount = row['paymentTotalAmount'] ?? row['estimatedPrice'];
  final displayId = _text(
    row['shipmentCode'],
    fallback: 'SHP-${_text(row['id'], fallback: '0')}',
  );

  return AdminShipmentManagementMock(
    id: displayId,
    backendId: _asInt(row['id']),
    assignmentBackendId: _asInt(row['latestAssignmentId']),
    customer: _text(row['customerName'], fallback: 'Customer'),
    category: _text(row['categoryName'], fallback: 'Shipment'),
    route: _route(row),
    pickupDate: _dateLabel(pickupDate),
    dateFilter: _dateFilter(pickupDate ?? _parseDate(row['createdAt'])),
    driver: driver,
    status: _statusLabel(row['shipmentStatus']),
    vehicle: latestVehicle.isNotEmpty
        ? latestVehicle
        : _statusLabel(row['vehiclePreference']),
    amount: _money(amount),
  );
}

AdminDriverManagementMock _mapDriverRow(Map<String, dynamic> row) {
  final address = _join([
    row['addressLine1'],
    row['addressLine2'],
    row['city'],
    row['state'],
    row['postalCode'],
  ]);
  final completedTrips = _asNum(row['completedTrips']).toInt();
  final rating = _asNum(row['rating']).toDouble();

  return AdminDriverManagementMock(
    id: _text(row['driverCode'], fallback: 'DRV-${_text(row['id'])}'),
    backendId: _asInt(row['id']),
    name: _text(row['name'], fallback: 'Driver'),
    username: _text(row['username'], fallback: 'driver'),
    email: _text(row['email'], fallback: '-'),
    phone: _text(row['phone'], fallback: '-'),
    address: address.isEmpty ? 'Address not available' : address,
    temporaryPassword: 'Managed by API',
    zone: _text(row['city'] ?? row['state'], fallback: 'Assigned zone'),
    assignedVehicle: _text(
      row['assignedVehicleNumber'] ?? row['assignedVehicleRegistrationNumber'],
      fallback: 'Unassigned vehicle',
    ),
    status: _statusLabel(row['driverStatus']),
    availability: _driverAvailability(row['availabilityStatus']),
    licenseNumber: _text(row['licenseNumber'], fallback: '-'),
    licenseClass: 'Transport',
    licenseExpiry:
        _parseDate(row['licenseExpiryDate']) ??
        DateTime.now().add(const Duration(days: 365)),
    completedTrips: completedTrips,
    onTimePercentage: completedTrips == 0 ? 0 : 94,
    safetyScore: 100,
    rating: rating,
    lastCheckIn: _relativeOrDate(row['lastLoginAt'] ?? row['updatedAt']),
  );
}

AdminVehicleManagementMock _mapVehicleRow(Map<String, dynamic> row) {
  final activeAssignments = _asNum(row['activeAssignments']).toInt();
  return AdminVehicleManagementMock(
    id: _text(row['vehicleNumber'], fallback: 'VEH-${_text(row['id'])}'),
    backendId: _asInt(row['id']),
    vehicleNumber: _text(row['vehicleNumber'], fallback: 'Vehicle'),
    type: _statusLabel(row['vehicleType']),
    capacity: '${_asNum(row['capacityKg']).toStringAsFixed(0)} kg',
    model: _text(row['model'], fallback: 'Fleet vehicle'),
    fuelType: _statusLabel(row['fuelType']),
    registration: _text(row['registrationNumber'], fallback: '-'),
    insuranceExpiry:
        _parseDate(row['insuranceExpiryDate']) ??
        DateTime.now().add(const Duration(days: 365)),
    serviceDue:
        _parseDate(row['serviceDueDate']) ??
        DateTime.now().add(const Duration(days: 30)),
    availability: _vehicleAvailability(row['availabilityStatus']),
    assignedDriver: _text(row['assignedDriverName'], fallback: 'Unassigned'),
    assignedTrip: activeAssignments > 0
        ? '$activeAssignments active trip(s)'
        : null,
    hub: 'Primary hub',
    odometer: 'Not connected',
    lastInspection: _relativeOrDate(row['updatedAt'] ?? row['createdAt']),
    notes: _text(row['notes'], fallback: 'No fleet notes.'),
  );
}

AdminCustomerManagementMock _mapCustomerRow(Map<String, dynamic> row) {
  final address = _join([
    row['addressLine1'],
    row['addressLine2'],
    row['city'],
    row['state'],
    row['postalCode'],
  ]);
  final lastShipment = row['lastShipmentCode'] ?? row['lastShipmentId'];

  return AdminCustomerManagementMock(
    id: _text(row['customerCode'], fallback: 'CUS-${_text(row['id'])}'),
    backendId: _asInt(row['id']),
    name: _text(row['name'], fallback: 'Customer'),
    email: _text(row['email'], fallback: '-'),
    phone: _text(row['phone'], fallback: '-'),
    totalShipments: _asNum(
      row['shipmentCount'] ?? row['totalShipments'],
    ).toInt(),
    status: _statusLabel(row['accountStatus'] ?? row['userStatus']),
    registeredDate:
        _parseDate(row['registeredAt'] ?? row['createdAt']) ?? DateTime.now(),
    address: address.isEmpty ? 'Address not available' : address,
    lastShipmentId: lastShipment?.toString(),
    preferredCategory: 'Shipment customer',
    lifetimeValue: _money(row['totalPaidAmount']),
    openIssues: 0,
    lastActivity: _relativeOrDate(row['lastShipmentAt'] ?? row['updatedAt']),
  );
}

AdminPaymentManagementMock _mapPaymentRow(Map<String, dynamic> row) {
  final date = _parseDate(row['paidAt'] ?? row['createdAt']) ?? DateTime.now();
  final total = _asNum(row['totalAmount']);
  final fee = _asNum(row['feeAmount']);

  return AdminPaymentManagementMock(
    id: _text(row['paymentCode'], fallback: 'PAY-${_text(row['id'])}'),
    backendId: _asInt(row['id']),
    shipmentId: _text(row['shipmentCode'], fallback: '-'),
    customer: _text(row['customerName'], fallback: 'Customer'),
    amount: _money(total),
    method: _statusLabel(row['paymentMethod']),
    status: _statusLabel(row['paymentStatus']),
    date: date,
    dateFilter: _dateFilter(date),
    transactionReference: _text(row['transactionReference'], fallback: '-'),
    invoiceNumber: _text(row['invoiceNumber'], fallback: '-'),
    gateway: 'CargoConnect API',
    fee: _money(fee),
    netAmount: _money(total - fee),
    notes: 'Loaded from payment API.',
  );
}

AdminInvoiceManagementMock _mapInvoiceRow(Map<String, dynamic> row) {
  final date =
      _parseDate(row['issuedAt'] ?? row['createdAt']) ?? DateTime.now();
  final total = _asNum(row['totalAmount']);
  final tax = _asNum(row['taxAmount']);
  final discount = _asNum(row['discountAmount']);
  final subtotal = _asNum(row['subtotalAmount']);

  return AdminInvoiceManagementMock(
    backendId: _asInt(row['id']),
    invoiceNumber: _text(
      row['invoiceNumber'],
      fallback: 'INV-${_text(row['id'])}',
    ),
    shipmentId: _text(row['shipmentCode'], fallback: '-'),
    customer: _text(row['customerName'], fallback: 'Customer'),
    total: _money(total),
    paymentStatus: _statusLabel(row['paymentStatus']),
    generatedDate: date,
    dateFilter: _dateFilter(date),
    invoiceStatus: _statusLabel(row['invoiceStatus']),
    billingAddress: _text(
      row['billingAddress'],
      fallback: 'Billing address not available',
    ),
    route: _route(row),
    packageSummary: _text(row['categoryName'], fallback: 'Shipment service'),
    baseCharge: _money(subtotal),
    handlingFee: _money(0),
    tax: _money(tax),
    discount: discount == 0 ? _money(0) : '-${_money(discount)}',
    paymentMethod: _statusLabel(row['paymentMethod']),
    notes: 'Loaded from invoice API.',
  );
}

AdminDriverAssignmentMock _driverToAssignment(
  AdminDriverManagementMock driver,
) {
  final busy = driver.availability == 'On Trip';
  return AdminDriverAssignmentMock(
    id: driver.id,
    backendId: driver.backendId,
    name: driver.name,
    phone: driver.phone,
    zone: driver.zone,
    rating: driver.completedTrips == 0
        ? 'New'
        : driver.rating.toStringAsFixed(1),
    status: driver.status == 'Active' && !busy
        ? 'Available'
        : driver.availability,
    currentShipmentId: busy ? 'Active trip' : null,
  );
}

AdminVehicleAssignmentMock _vehicleToAssignment(
  AdminVehicleManagementMock vehicle,
) {
  final busy = vehicle.assignedTrip != null || vehicle.availability == 'Busy';
  return AdminVehicleAssignmentMock(
    id: vehicle.id,
    backendId: vehicle.backendId,
    label: vehicle.vehicleNumber,
    type: vehicle.type,
    registration: vehicle.registration,
    capacity: vehicle.capacity,
    status: busy ? 'Busy' : vehicle.availability,
    currentShipmentId: busy ? vehicle.assignedTrip ?? 'Active trip' : null,
  );
}

int _backendId(Object object) {
  final backendId = switch (object) {
    AdminShipmentManagementMock item => item.backendId ?? int.tryParse(item.id),
    AdminShipmentDetailMock item => item.backendId ?? int.tryParse(item.id),
    AdminDriverAssignmentMock item => item.backendId ?? int.tryParse(item.id),
    AdminVehicleAssignmentMock item => item.backendId ?? int.tryParse(item.id),
    AdminDriverManagementMock item => item.backendId ?? int.tryParse(item.id),
    AdminVehicleManagementMock item => item.backendId ?? int.tryParse(item.id),
    AdminCustomerManagementMock item => item.backendId ?? int.tryParse(item.id),
    AdminPaymentManagementMock item => item.backendId ?? int.tryParse(item.id),
    AdminInvoiceManagementMock item =>
      item.backendId ?? int.tryParse(item.invoiceNumber),
    _ => null,
  };

  if (backendId == null || backendId <= 0) {
    throw const ApiException(message: 'Record is missing its backend ID.');
  }
  return backendId;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is List) {
    return value.map(_map).toList();
  }
  return const <Map<String, dynamic>>[];
}

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') {
    return fallback;
  }
  return text;
}

num _asNum(Object? value) {
  if (value is num) {
    return value;
  }
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _parseDate(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text)?.toLocal();
}

String _dateLabel(DateTime? date) {
  if (date == null) {
    return 'Not scheduled';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${months[date.month - 1]} ${date.day}, $hour:$minute $suffix';
}

String _dateFilter(DateTime? date) {
  if (date == null) {
    return 'Past';
  }
  final today = DateUtils.dateOnly(DateTime.now());
  final value = DateUtils.dateOnly(date);
  final days = value.difference(today).inDays;
  if (days == 0) {
    return 'Today';
  }
  if (days.abs() <= 7) {
    return 'This Week';
  }
  if (value.year == today.year && value.month == today.month) {
    return 'This Month';
  }
  return value.isBefore(today) ? 'Past' : 'This Month';
}

String _relativeOrDate(Object? value) {
  final date = _parseDate(value);
  if (date == null) {
    return 'Recently updated';
  }
  return _dateLabel(date);
}

String _statusLabel(Object? value) {
  final text = _text(value, fallback: '-');
  if (text == '-') {
    return text;
  }
  return text
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _driverAvailability(Object? value) {
  return switch (_text(value).toLowerCase()) {
    'available' => 'Available',
    'busy' => 'On Trip',
    'offline' => 'Offline',
    'on_leave' || 'leave' => 'On Leave',
    _ => _statusLabel(value),
  };
}

String _vehicleAvailability(Object? value) {
  return switch (_text(value).toLowerCase()) {
    'available' => 'Available',
    'assigned' || 'busy' => 'Busy',
    'maintenance' => 'Maintenance',
    'inactive' => 'Out of Service',
    'on_leave' => 'On Leave',
    _ => _statusLabel(value),
  };
}

String _route(Map<String, dynamic> row) {
  final pickup = _text(
    row['pickupCity'] ?? row['pickupAddress'],
    fallback: 'Pickup',
  );
  final delivery = _text(
    row['deliveryCity'] ?? row['deliveryAddress'],
    fallback: 'Delivery',
  );
  return '$pickup to $delivery';
}

String _address(Map<String, dynamic> row, String prefix) {
  return _join([
    row['${prefix}Address'],
    row['${prefix}City'],
    row['${prefix}State'],
    row['${prefix}PostalCode'],
  ]);
}

String _join(List<Object?> values) {
  return values
      .map((value) => _text(value))
      .where((value) => value.isNotEmpty)
      .join(', ');
}

String _money(Object? value) {
  final amount = _asNum(value);
  final decimals = amount % 1 == 0 ? 0 : 2;
  return 'INR ${amount.toStringAsFixed(decimals)}';
}

String _count(Object? value) => _asNum(value).toInt().toString();

String _label(Object? value) => _statusLabel(value);

String _shortLabel(String value) {
  if (value.length <= 10) {
    return value;
  }
  return value.split(' ').map((part) => part.isEmpty ? '' : part[0]).join();
}

String _notificationStatus(Map<String, dynamic> json) {
  final explicit = _text(json['status']);
  if (explicit.isNotEmpty) {
    return _statusLabel(explicit);
  }
  if (json['isRead'] == true ||
      json['readAt'] != null ||
      json['read'] == true) {
    return 'Read';
  }
  return 'Unread';
}

String _dateOnlyLabel(Object? value) {
  final date = value is DateTime ? value : _parseDate(value);
  if (date == null) {
    return _text(value, fallback: 'Not dated');
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _percent(num part, num total) {
  if (total <= 0) {
    return '0%';
  }
  return '${((part / total) * 100).toStringAsFixed(1)}%';
}

int _daysUntil(DateTime date) {
  return DateUtils.dateOnly(
    date,
  ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
}

num _moneyToNum(String value) {
  final normalized = value
      .replaceAll('INR', '')
      .replaceAll(',', '')
      .replaceAll('L', '')
      .trim();
  return num.tryParse(normalized) ?? 0;
}

AdminDriverReportMock _driverReportRow(Map<String, dynamic> row) {
  final assigned = _asNum(row['assignedTripsInRange']);
  final completed = _asNum(
    row['completedAssignmentsInRange'] ?? row['completedTrips'],
  );
  final rating = _asNum(row['rating']).toDouble();
  final acceptance = assigned <= 0 ? 0 : (completed / assigned) * 100;
  final performance = (rating * 20).clamp(0, 100).round();
  return AdminDriverReportMock(
    id: _text(row['driverCode'], fallback: 'DRV-${_text(row['id'])}'),
    name: _text(row['driverName'] ?? row['name'], fallback: 'Driver'),
    zone: _text(row['city'] ?? row['state'], fallback: 'Backend zone'),
    status: _driverAvailability(row['availabilityStatus']),
    completedTrips: _asNum(row['completedTrips'] ?? completed).toInt(),
    acceptanceRate: acceptance.toDouble(),
    delays: _asNum(row['delaysInRange'] ?? row['delayCount']).toInt(),
    performanceScore: performance,
    emergencyCount: _asNum(row['emergencyReportsInRange']).toInt(),
    onTimeRate: acceptance.toDouble(),
    rating: rating,
  );
}

AdminVehicleReportMock _vehicleReportRow(Map<String, dynamic> row) {
  final assignments = _asNum(row['assignedTripsInRange']).toInt();
  final activeTrips = _asNum(row['activeTripsInRange']).toInt();
  final utilization = activeTrips > 0
      ? 100
      : assignments > 0
      ? (assignments * 12).clamp(12, 96)
      : 0;
  return AdminVehicleReportMock(
    id: _text(row['vehicleNumber'], fallback: 'VEH-${_text(row['id'])}'),
    vehicleNumber: _text(row['vehicleNumber'], fallback: 'Vehicle'),
    type: _statusLabel(row['vehicleType']),
    availability: _vehicleAvailability(row['availabilityStatus']),
    utilization: utilization,
    serviceDue:
        _parseDate(row['serviceDueDate']) ??
        DateTime.now().add(const Duration(days: 30)),
    assignmentCount: assignments,
    breakdownCount: _asNum(row['breakdownReportsInRange']).toInt(),
    assignedDriver: _text(row['assignedDriverName'], fallback: 'Unassigned'),
    assignedTrip: activeTrips > 0 ? '$activeTrips active trip(s)' : null,
    hub: _text(row['hub'], fallback: 'Primary hub'),
  );
}
