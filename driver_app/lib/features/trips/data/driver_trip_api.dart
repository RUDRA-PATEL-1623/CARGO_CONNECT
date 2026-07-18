import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'driver_trip_models.dart';

final driverTripApiProvider = Provider<DriverTripApi>((ref) {
  return DriverTripApi(dio: ref.watch(dioClientProvider));
});

class DriverTripApi {
  const DriverTripApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<DriverTripListResult> listTrips({
    int page = 1,
    int limit = 50,
    String? search,
    String? group,
    String? status,
    String? shipmentStatus,
    String? dateFrom,
    String? dateTo,
  }) async {
    final data = await _get(
      '/driver/trips',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (group != null && group.isNotEmpty) 'group': group,
        if (status != null && status.isNotEmpty) 'status': status,
        if (shipmentStatus != null && shipmentStatus.isNotEmpty)
          'shipmentStatus': shipmentStatus,
        if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
      },
    );

    return DriverTripListResult.fromJson(data);
  }

  Future<DriverTripListResult> listTripHistory({
    int page = 1,
    int limit = 50,
    String? search,
    String? status,
    String? shipmentStatus,
    String? dateFrom,
    String? dateTo,
  }) async {
    final data = await _get(
      '/driver/trips/history',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (shipmentStatus != null && shipmentStatus.isNotEmpty)
          'shipmentStatus': shipmentStatus,
        if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
      },
    );

    return DriverTripListResult.fromJson(data);
  }

  Future<DriverTripDetail> getTripDetails(int assignmentId) async {
    final data = await _get('/driver/trips/$assignmentId');
    return DriverTripDetail.fromJson(data);
  }

  Future<DriverTripDetail> resolveTripDetails(String lookup) async {
    final assignmentId = int.tryParse(lookup);
    if (assignmentId != null) {
      return getTripDetails(assignmentId);
    }

    final result = await listTrips(search: lookup, limit: 1);
    if (result.trips.isEmpty) {
      throw ApiException(
        message:
            'No backend assignment matched "$lookup". Open Assigned trips and select a live trip.',
        statusCode: 404,
      );
    }

    return getTripDetails(result.trips.first.id);
  }

  Future<DriverTripSummary> acceptTrip(int assignmentId) async {
    return _patchTrip('/driver/trips/$assignmentId/accept');
  }

  Future<DriverTripSummary> rejectTrip({
    required int assignmentId,
    required String reason,
  }) async {
    return _patchTrip(
      '/driver/trips/$assignmentId/reject',
      body: {'reason': reason.trim()},
    );
  }

  Future<DriverTripSummary> startTrip(
    int assignmentId, {
    String? notes,
    String? locationText,
    int? etaMinutes,
  }) async {
    return _patchTrip(
      '/driver/trips/$assignmentId/start',
      body: _progressBody(
        notes: notes,
        locationText: locationText,
        etaMinutes: etaMinutes,
      ),
    );
  }

  Future<DriverTripSummary> markPickupCompleted(
    int assignmentId, {
    String? notes,
    String? locationText,
  }) async {
    return _patchTrip(
      '/driver/trips/$assignmentId/pickup-completed',
      body: _progressBody(notes: notes, locationText: locationText),
    );
  }

  Future<DriverTripSummary> markInTransit(
    int assignmentId, {
    String? notes,
    String? locationText,
    int? etaMinutes,
  }) async {
    return _patchTrip(
      '/driver/trips/$assignmentId/in-transit',
      body: _progressBody(
        notes: notes,
        locationText: locationText,
        etaMinutes: etaMinutes,
      ),
    );
  }

  Future<DriverTripSummary> updateTripStatus(
    int assignmentId, {
    String? status,
    String? notes,
    String? delayReason,
    String? locationText,
    int? etaMinutes,
  }) async {
    return _patchTrip(
      '/driver/trips/$assignmentId/status-update',
      body: {
        ..._progressBody(
          notes: notes,
          locationText: locationText,
          etaMinutes: etaMinutes,
        ),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (delayReason != null && delayReason.trim().isNotEmpty)
          'delayReason': delayReason.trim(),
      },
    );
  }

  Future<DriverTripSummary> markDeliveryCompleted(
    int assignmentId, {
    String? notes,
    String? locationText,
  }) async {
    return _patchTrip(
      '/driver/trips/$assignmentId/delivery-completed',
      body: _progressBody(notes: notes, locationText: locationText),
    );
  }

  Future<DriverTripSummary> completeTrip(
    int assignmentId, {
    String? notes,
    String? locationText,
  }) async {
    return _patchTrip(
      '/driver/trips/$assignmentId/complete',
      body: _progressBody(notes: notes, locationText: locationText),
    );
  }

  Future<DriverProof> uploadPickupProof({
    required int assignmentId,
    required Uint8List fileBytes,
    required String fileName,
    String? notes,
    String? locationText,
  }) async {
    return _uploadProof(
      path: '/driver/trips/$assignmentId/proofs/pickup',
      fileBytes: fileBytes,
      fileName: fileName,
      notes: notes,
      locationText: locationText,
    );
  }

  Future<DriverProof> uploadDeliveryProof({
    required int assignmentId,
    required Uint8List fileBytes,
    required String fileName,
    String? notes,
    String? locationText,
  }) async {
    return _uploadProof(
      path: '/driver/trips/$assignmentId/proofs/delivery',
      fileBytes: fileBytes,
      fileName: fileName,
      notes: notes,
      locationText: locationText,
    );
  }

  Future<DriverTripSummary> _patchTrip(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final data = await _patch(path, body: body ?? const {});
    return DriverTripSummary.fromJson(_asMap(data['trip']));
  }

  Future<DriverProof> _uploadProof({
    required String path,
    required Uint8List fileBytes,
    required String fileName,
    String? notes,
    String? locationText,
  }) async {
    final data = await _postMultipart(
      path,
      FormData.fromMap({
        'proof': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: DioMediaType.parse(_mimeTypeForPath(fileName)),
        ),
        'capturedAt': DateTime.now().toIso8601String(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (locationText != null && locationText.trim().isNotEmpty)
          'locationText': locationText.trim(),
      }),
    );

    return DriverProof.fromJson(_asMap(data['proof']));
  }

  Map<String, dynamic> _progressBody({
    String? notes,
    String? locationText,
    int? etaMinutes,
  }) {
    return {
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (locationText != null && locationText.trim().isNotEmpty)
        'locationText': locationText.trim(),
      if (etaMinutes != null && etaMinutes > 0) 'etaMinutes': etaMinutes,
    };
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      return _readEnvelopeData(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    }
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.patch<Object?>(path, data: body);
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

String _mimeTypeForPath(String filePath) {
  final lower = filePath.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}
