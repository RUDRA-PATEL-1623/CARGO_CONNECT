import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/auth_token_storage.dart';
import 'driver_session.dart';

final driverAuthApiProvider = Provider<DriverAuthApi>((ref) {
  return DriverAuthApi(
    dio: ref.watch(dioClientProvider),
    tokenStorage: ref.watch(authTokenStorageProvider),
  );
});

class DriverAuthApi {
  const DriverAuthApi({
    required Dio dio,
    required AuthTokenStorage tokenStorage,
  }) : _dio = dio,
       _tokenStorage = tokenStorage;

  final Dio _dio;
  final AuthTokenStorage _tokenStorage;

  Future<DriverSession> login({
    required String identifier,
    required String password,
  }) async {
    final data = await _post(
      '/auth/driver/login',
      body: {'identifier': identifier.trim(), 'password': password},
    );

    final session = DriverSession.fromLoginData(data);
    if (session.role != 'driver') {
      throw const ApiException(message: 'Driver credentials are required.');
    }
    await _tokenStorage.saveSession(session);
    return session;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _post(
      '/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post<Object?>('/driver/logout');
    } on DioException {
      // Logout is token-safe; the local session must be cleared even if the
      // stateless acknowledgement cannot be reached.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<Map<String, dynamic>> _post(
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

  Map<String, dynamic> _readEnvelopeData(Object? responseData) {
    return ApiResponse.fromJson(responseData).dataAsMap();
  }
}
