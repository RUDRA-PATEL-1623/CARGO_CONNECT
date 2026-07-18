import 'api_exception.dart';

class ApiResponse {
  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
    this.pagination,
  });

  final bool success;
  final String message;
  final Object? data;
  final Map<String, dynamic>? pagination;

  factory ApiResponse.fromJson(Object? responseData) {
    final envelope = _asMap(responseData);
    if (envelope.isEmpty) {
      throw const FormatException('Empty API response.');
    }

    if (envelope['success'] == false) {
      throw ApiException.fromResponseData(envelope);
    }

    return ApiResponse(
      success: envelope['success'] != false,
      message: envelope['message']?.toString() ?? 'Success',
      data: envelope['data'],
      pagination: _nullableMap(envelope['pagination']),
    );
  }

  Map<String, dynamic> dataAsMap() => _asMap(data);

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static Map<String, dynamic>? _nullableMap(Object? value) {
    final map = _asMap(value);
    return map.isEmpty ? null : map;
  }
}
