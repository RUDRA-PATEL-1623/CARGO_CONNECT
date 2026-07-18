import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../shipment/data/customer_shipment_api.dart';

final customerSupportApiProvider = Provider<CustomerSupportApi>((ref) {
  return CustomerSupportApi(dio: ref.watch(dioClientProvider));
});

class CustomerSupportApi {
  const CustomerSupportApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<CustomerSupportIssueList> listIssues({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? priority,
    String? issueType,
    int? shipmentId,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};

    void add(String key, Object? value) {
      if (value == null) {
        return;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        query[key] = value;
      }
    }

    add('search', search);
    add('status', status);
    add('priority', priority);
    add('issueType', issueType);
    add('shipmentId', shipmentId);

    final data = await _request(
      () =>
          _dio.get<Object?>('/customer/support/issues', queryParameters: query),
    );
    return CustomerSupportIssueList.fromJson(_asMap(data));
  }

  Future<CustomerSupportIssue> createIssue(
    CustomerSupportIssueRequest request,
  ) async {
    final data = await _request(
      () => _dio.post<Object?>(
        '/customer/support/issues',
        data: request.toJson(),
      ),
    );
    return CustomerSupportIssue.fromJson(_asMap(_asMap(data)['issue']));
  }

  Future<Object?> _request(Future<Response<Object?>> Function() request) async {
    try {
      final response = await request();
      return ApiResponse.fromJson(response.data).data;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    }
  }
}

class CustomerSupportIssueRequest {
  const CustomerSupportIssueRequest({
    this.shipmentId,
    required this.issueType,
    required this.priority,
    required this.subject,
    required this.description,
    this.attachmentUrl,
  });

  final int? shipmentId;
  final String issueType;
  final String priority;
  final String subject;
  final String description;
  final String? attachmentUrl;

  Map<String, dynamic> toJson() => {
    if (shipmentId != null) 'shipmentId': shipmentId,
    'issueType': issueType,
    'priority': priority,
    'subject': subject.trim(),
    'description': description.trim(),
    if (attachmentUrl?.trim().isNotEmpty == true)
      'attachmentUrl': attachmentUrl!.trim(),
  };
}

class CustomerSupportIssueList {
  const CustomerSupportIssueList({
    required this.issues,
    required this.meta,
    this.emptyState,
  });

  final List<CustomerSupportIssue> issues;
  final ApiPaginationMeta meta;
  final ApiEmptyState? emptyState;

  factory CustomerSupportIssueList.fromJson(Map<String, dynamic> json) {
    final rows = json['issues'] is List ? json['issues'] as List : const [];
    return CustomerSupportIssueList(
      issues: rows
          .whereType<Map>()
          .map((row) => CustomerSupportIssue.fromJson(_asMap(row)))
          .toList(growable: false),
      meta: ApiPaginationMeta.fromJson(_asMap(json['meta'])),
      emptyState: _nullableMap(json['emptyState']) == null
          ? null
          : ApiEmptyState.fromJson(_asMap(json['emptyState'])),
    );
  }
}

class CustomerSupportIssue {
  const CustomerSupportIssue({
    required this.id,
    required this.issueCode,
    required this.issueType,
    required this.priority,
    required this.subject,
    required this.description,
    required this.issueStatus,
    this.shipmentId,
    this.shipmentCode,
    this.adminResponse,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String issueCode;
  final int? shipmentId;
  final String? shipmentCode;
  final String issueType;
  final String priority;
  final String subject;
  final String description;
  final String issueStatus;
  final String? adminResponse;
  final String? createdAt;
  final String? updatedAt;

  factory CustomerSupportIssue.fromJson(Map<String, dynamic> json) {
    return CustomerSupportIssue(
      id: _asInt(json['id']),
      issueCode: json['issueCode']?.toString() ?? '',
      shipmentId: _asNullableInt(json['shipmentId']),
      shipmentCode: json['shipmentCode']?.toString(),
      issueType: json['issueType']?.toString() ?? 'other',
      priority: json['priority']?.toString() ?? 'medium',
      subject: json['subject']?.toString() ?? 'Support issue',
      description: json['description']?.toString() ?? '',
      issueStatus: json['issueStatus']?.toString() ?? 'open',
      adminResponse: json['adminResponse']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
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
