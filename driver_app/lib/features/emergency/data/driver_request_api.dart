import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

final driverRequestApiProvider = Provider<DriverRequestApi>((ref) {
  return DriverRequestApi(dio: ref.watch(dioClientProvider));
});

class DriverRequestApi {
  const DriverRequestApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<DriverReportResponse> createEmergencyReport({
    required String reportType,
    required String severity,
    required String description,
    int? assignmentId,
    int? vehicleId,
    String? locationText,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    final attachment = _optionalMultipartFile(
      bytes: attachmentBytes,
      fileName: attachmentName,
      filePath: attachmentPath,
    );
    final data = await _postMultipart(
      '/driver/reports/emergency',
      FormData.fromMap({
        'reportType': reportType,
        'severity': severity,
        'description': description.trim(),
        if (assignmentId != null) 'assignmentId': assignmentId.toString(),
        if (vehicleId != null && vehicleId > 0)
          'vehicleId': vehicleId.toString(),
        if (locationText != null && locationText.trim().isNotEmpty)
          'locationText': locationText.trim(),
        ...(attachment == null
            ? const <String, Object>{}
            : {'attachment': attachment}),
      }),
    );

    return DriverReportResponse.fromJson(_asMap(data['report']));
  }

  Future<DriverReportResponse> createBreakdownReport({
    required int vehicleId,
    required String issueType,
    required String severity,
    required String description,
    int? assignmentId,
    String? locationText,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    final attachment = _optionalMultipartFile(
      bytes: attachmentBytes,
      fileName: attachmentName,
      filePath: attachmentPath,
    );
    final data = await _postMultipart(
      '/driver/reports/breakdown',
      FormData.fromMap({
        'vehicleId': vehicleId.toString(),
        'issueType': issueType,
        'severity': severity,
        'description': description.trim(),
        if (assignmentId != null) 'assignmentId': assignmentId.toString(),
        if (locationText != null && locationText.trim().isNotEmpty)
          'locationText': locationText.trim(),
        ...(attachment == null
            ? const <String, Object>{}
            : {'attachment': attachment}),
      }),
    );

    return DriverReportResponse.fromJson(_asMap(data['report']));
  }

  Future<DriverFuelRequestResponse> createFuelRequest({
    required double fuelAmountLiters,
    required double billAmount,
    required String fuelStation,
    String? notes,
    int? assignmentId,
    int? vehicleId,
  }) async {
    final body = <String, dynamic>{
      'fuelAmountLiters': fuelAmountLiters,
      'billAmount': billAmount,
      'fuelStation': fuelStation.trim(),
    };
    final requestNotes = notes?.trim();
    if (requestNotes != null && requestNotes.isNotEmpty) {
      body['notes'] = requestNotes;
    }
    if (assignmentId != null) {
      body['assignmentId'] = assignmentId;
    }
    if (vehicleId != null && vehicleId > 0) {
      body['vehicleId'] = vehicleId;
    }

    final data = await _postJson('/driver/fuel-requests', body: body);

    return DriverFuelRequestResponse.fromJson(_asMap(data['fuelRequest']));
  }

  Future<DriverFuelRequestResponse> uploadFuelBill({
    required int fuelRequestId,
    required Uint8List billBytes,
    required String billName,
    String? notes,
  }) async {
    final data = await _postMultipart(
      '/driver/fuel-requests/$fuelRequestId/bill',
      FormData.fromMap({
        'bill': MultipartFile.fromBytes(
          billBytes,
          filename: billName,
          contentType: DioMediaType.parse(_mimeTypeForPath(billName)),
        ),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );

    return DriverFuelRequestResponse.fromJson(_asMap(data['fuelRequest']));
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.post<Object?>(path, data: body);
      return _readEnvelopeData(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    }
  }

  Future<Map<String, dynamic>> _postMultipart(
    String path,
    FormData formData,
  ) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _readEnvelopeData(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    }
  }

  Map<String, dynamic> _readEnvelopeData(Object? responseData) {
    final envelope = _asMap(responseData);
    if (envelope.isEmpty) {
      throw const FormatException('Empty API response.');
    }

    if (envelope['success'] == false) {
      throw ApiException.fromResponseData(envelope);
    }

    return _asMap(envelope['data']);
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
}

class DriverReportResponse {
  const DriverReportResponse({
    required this.id,
    required this.reportCode,
    required this.reportType,
    required this.reportStatus,
  });

  factory DriverReportResponse.fromJson(Map<String, dynamic> json) {
    return DriverReportResponse(
      id: _toInt(json['id']),
      reportCode: json['reportCode']?.toString() ?? '',
      reportType: json['reportType']?.toString() ?? '',
      reportStatus: json['reportStatus']?.toString() ?? '',
    );
  }

  final int id;
  final String reportCode;
  final String reportType;
  final String reportStatus;
}

class DriverFuelRequestResponse {
  const DriverFuelRequestResponse({
    required this.id,
    required this.requestCode,
    required this.requestStatus,
  });

  factory DriverFuelRequestResponse.fromJson(Map<String, dynamic> json) {
    return DriverFuelRequestResponse(
      id: _toInt(json['id']),
      requestCode: json['requestCode']?.toString() ?? '',
      requestStatus: json['requestStatus']?.toString() ?? '',
    );
  }

  final int id;
  final String requestCode;
  final String requestStatus;
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

MultipartFile? _optionalMultipartFile({
  required Uint8List? bytes,
  required String? fileName,
  required String? filePath,
}) {
  if (bytes != null) {
    final safeName = _safeFileName(fileName, filePath);
    return MultipartFile.fromBytes(
      bytes,
      filename: safeName,
      contentType: DioMediaType.parse(_mimeTypeForPath(safeName)),
    );
  }

  return null;
}

String _safeFileName(String? fileName, String? filePath) {
  final name = fileName?.trim();
  if (name != null && name.isNotEmpty) {
    return name;
  }
  final path = filePath?.trim();
  if (path != null && path.isNotEmpty) {
    return _fileNameFromPath(path);
  }
  return 'driver-upload.jpg';
}

String _fileNameFromPath(String filePath) {
  final parts = filePath.split(RegExp(r'[\\/]+'));
  return parts.isEmpty || parts.last.isEmpty ? 'driver-upload.jpg' : parts.last;
}

String _mimeTypeForPath(String filePath) {
  final lower = filePath.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.pdf')) {
    return 'application/pdf';
  }
  return 'image/jpeg';
}
