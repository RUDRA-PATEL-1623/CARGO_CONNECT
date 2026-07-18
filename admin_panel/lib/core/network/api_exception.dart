import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const [],
  });

  final String message;
  final int? statusCode;
  final List<ApiFieldError> fieldErrors;

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;

    if (response?.data != null) {
      return ApiException.fromResponseData(
        response!.data,
        statusCode: statusCode,
      );
    }

    return ApiException(
      message: _messageForDioType(error.type),
      statusCode: statusCode,
    );
  }

  factory ApiException.fromResponseData(Object? data, {int? statusCode}) {
    if (data is Map<String, dynamic>) {
      return _fromMap(data, statusCode: statusCode);
    }
    if (data is Map) {
      return _fromMap(
        data.map((key, value) => MapEntry(key.toString(), value)),
        statusCode: statusCode,
      );
    }

    return ApiException(
      message: 'CargoConnect API returned an unexpected response.',
      statusCode: statusCode,
    );
  }

  static ApiException _fromMap(Map<String, dynamic> data, {int? statusCode}) {
    final errors = _parseFieldErrors(data['errors']);
    final message = _readMessage(data, errors);

    return ApiException(
      message: message,
      statusCode: statusCode,
      fieldErrors: errors,
    );
  }

  static List<ApiFieldError> _parseFieldErrors(Object? errors) {
    if (errors is Map) {
      return errors.entries
          .map(
            (entry) => ApiFieldError(
              field: entry.key.toString(),
              message: _errorValueMessage(entry.value),
            ),
          )
          .toList(growable: false);
    }

    if (errors is List) {
      return errors
          .whereType<Map>()
          .map(
            (error) => ApiFieldError(
              field: error['field']?.toString(),
              message: error['message']?.toString() ?? 'Invalid value',
            ),
          )
          .toList(growable: false);
    }

    return const [];
  }

  static String _errorValueMessage(Object? value) {
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    if (value is Map && value['message'] != null) {
      return value['message'].toString();
    }
    final text = value?.toString();
    return text == null || text.isEmpty ? 'Invalid value' : text;
  }

  static String _readMessage(
    Map<String, dynamic> data,
    List<ApiFieldError> fieldErrors,
  ) {
    final message = data['message']?.toString();
    if (message != null && message.isNotEmpty) {
      if (fieldErrors.isNotEmpty) {
        return '$message: ${fieldErrors.first.message}';
      }
      return message;
    }

    if (fieldErrors.isNotEmpty) {
      return fieldErrors.first.message;
    }

    return 'CargoConnect API request failed.';
  }

  static String _messageForDioType(DioExceptionType type) {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Connection timed out. Check the backend server and base URL.',
      DioExceptionType.connectionError =>
        'Cannot connect to CargoConnect API. Start the backend or update the base URL.',
      DioExceptionType.cancel => 'Request was cancelled.',
      _ => 'CargoConnect API request failed.',
    };
  }

  @override
  String toString() => message;
}

class ApiFieldError {
  const ApiFieldError({required this.message, this.field});

  final String? field;
  final String message;
}
