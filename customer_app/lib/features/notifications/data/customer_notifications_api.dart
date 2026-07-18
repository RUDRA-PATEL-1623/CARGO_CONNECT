import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../shipment/data/customer_shipment_api.dart';

final customerNotificationsApiProvider = Provider<CustomerNotificationsApi>((
  ref,
) {
  return CustomerNotificationsApi(dio: ref.watch(dioClientProvider));
});

class CustomerNotificationsApi {
  const CustomerNotificationsApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<CustomerNotificationsData> listNotifications({
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};

    if (unreadOnly) {
      query['unreadOnly'] = true;
    }

    final data = await _request(
      () =>
          _dio.get<Object?>('/customer/notifications', queryParameters: query),
    );
    return CustomerNotificationsData.fromJson(_asMap(data));
  }

  Future<CustomerNotification> markRead(int notificationId) async {
    final data = await _request(
      () => _dio.patch<Object?>('/customer/notifications/$notificationId/read'),
    );
    return CustomerNotification.fromJson(_asMap(_asMap(data)['notification']));
  }

  Future<NotificationMutationResult> markAllRead() async {
    final data = await _request(
      () => _dio.patch<Object?>('/customer/notifications/read-all'),
    );
    return NotificationMutationResult.fromJson(_asMap(data));
  }

  Future<NotificationMutationResult> clearAll() async {
    final data = await _request(
      () => _dio.delete<Object?>('/customer/notifications/clear'),
    );
    return NotificationMutationResult.fromJson(_asMap(data));
  }

  Future<Object?> _request(Future<Response<Object?>> Function() request) async {
    try {
      final response = await request();
      final envelope = _asMap(response.data);
      if (envelope.isEmpty) {
        throw const FormatException('Empty API response.');
      }
      if (envelope['success'] == false) {
        throw ApiException.fromResponseData(envelope);
      }
      return envelope['data'];
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    }
  }
}

class CustomerNotificationsData {
  const CustomerNotificationsData({
    required this.notifications,
    required this.unreadCount,
    required this.meta,
    this.emptyState,
  });

  final List<CustomerNotification> notifications;
  final int unreadCount;
  final ApiPaginationMeta meta;
  final ApiEmptyState? emptyState;

  factory CustomerNotificationsData.fromJson(Map<String, dynamic> json) {
    final rows = json['notifications'] is List
        ? json['notifications'] as List
        : const [];

    return CustomerNotificationsData(
      notifications: rows
          .whereType<Map>()
          .map((row) => CustomerNotification.fromJson(_asMap(row)))
          .toList(growable: false),
      unreadCount: _asInt(json['unreadCount']),
      meta: ApiPaginationMeta.fromJson(_asMap(json['meta'])),
      emptyState: _nullableMap(json['emptyState']) == null
          ? null
          : ApiEmptyState.fromJson(_asMap(json['emptyState'])),
    );
  }
}

class CustomerNotification {
  const CustomerNotification({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.isRead,
    this.shipmentId,
    this.shipmentCode,
    this.channel,
    this.readAt,
    this.sentAt,
    this.createdAt,
  });

  final int id;
  final int? shipmentId;
  final String? shipmentCode;
  final String notificationType;
  final String title;
  final String message;
  final String? channel;
  final bool isRead;
  final String? readAt;
  final String? sentAt;
  final String? createdAt;

  factory CustomerNotification.fromJson(Map<String, dynamic> json) {
    return CustomerNotification(
      id: _asInt(json['id']),
      shipmentId: _asNullableInt(json['shipmentId']),
      shipmentCode: json['shipmentCode']?.toString(),
      notificationType: json['notificationType']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      channel: json['channel']?.toString(),
      isRead: json['isRead'] == true,
      readAt: json['readAt']?.toString(),
      sentAt: json['sentAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class NotificationMutationResult {
  const NotificationMutationResult({
    required this.updatedCount,
    required this.clearedCount,
    required this.unreadCount,
  });

  final int updatedCount;
  final int clearedCount;
  final int unreadCount;

  factory NotificationMutationResult.fromJson(Map<String, dynamic> json) {
    return NotificationMutationResult(
      updatedCount: _asInt(json['updatedCount']),
      clearedCount: _asInt(json['clearedCount']),
      unreadCount: _asInt(json['unreadCount']),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

Map<String, dynamic>? _nullableMap(Object? value) {
  if (value == null) {
    return null;
  }
  final map = _asMap(value);
  return map.isEmpty ? null : map;
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  return _asInt(value);
}
