import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/auth_token_storage.dart';
import 'auth_session.dart';

final customerAuthApiProvider = Provider<CustomerAuthApi>((ref) {
  return CustomerAuthApi(
    dio: ref.watch(dioClientProvider),
    tokenStorage: ref.watch(authTokenStorageProvider),
  );
});

class CustomerAuthApi {
  const CustomerAuthApi({
    required Dio dio,
    required AuthTokenStorage tokenStorage,
  }) : _dio = dio,
       _tokenStorage = tokenStorage;

  final Dio _dio;
  final AuthTokenStorage _tokenStorage;

  Future<AuthSession> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    final data = await _post(
      '/auth/customer/login',
      body: {'identifier': identifier.trim(), 'password': password},
    );

    final session = AuthSession.fromLoginData(data);
    if (session.role != 'customer') {
      throw const ApiException(message: 'Customer credentials are required.');
    }
    await _tokenStorage.saveSession(session, rememberMe: rememberMe);
    return session;
  }

  Future<CustomerRegistrationResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
    String? addressLine1,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
      'acceptTerms': acceptTerms,
    };

    final address = addressLine1?.trim();
    if (address != null && address.isNotEmpty) {
      body['address'] = {'addressLine1': address};
    }

    final data = await _post('/auth/customer/register', body: body);
    return CustomerRegistrationResult.fromJson(data);
  }

  Future<AuthSession> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    final data = await _post(
      '/auth/customer/verify-otp',
      body: {'email': email.trim().toLowerCase(), 'otp': otp.trim()},
    );

    final session = AuthSession.fromVerificationData(data);
    if (session.role != 'customer') {
      throw const ApiException(message: 'Customer credentials are required.');
    }
    await _tokenStorage.saveSession(session, rememberMe: true);
    return session;
  }

  Future<CustomerRegistrationResult> resendRegistrationOtp({
    required String email,
  }) async {
    final data = await _post(
      '/auth/customer/resend-otp',
      body: {'email': email.trim().toLowerCase()},
    );
    return CustomerRegistrationResult.fromJson(data);
  }

  Future<PasswordResetRequestResult> requestPasswordReset({
    required String identifier,
  }) async {
    final data = await _post(
      '/auth/forgot-password',
      body: {'identifier': identifier.trim()},
    );
    return PasswordResetRequestResult.fromJson(data);
  }

  Future<PasswordResetVerificationResult> verifyResetOtp({
    required String identifier,
    required String otp,
  }) async {
    final data = await _post(
      '/auth/verify-reset-otp',
      body: {'identifier': identifier.trim(), 'otp': otp.trim()},
    );
    return PasswordResetVerificationResult.fromJson(data);
  }

  Future<void> createNewPassword({
    required String identifier,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _post(
      '/auth/create-new-password',
      body: {
        'identifier': identifier.trim(),
        'resetToken': resetToken.trim(),
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
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

  Future<void> logout() {
    return _tokenStorage.clear();
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

class CustomerRegistrationResult {
  const CustomerRegistrationResult({
    required this.destination,
    this.developmentOtp,
    this.expiresInMinutes,
  });

  final String destination;
  final String? developmentOtp;
  final int? expiresInMinutes;

  factory CustomerRegistrationResult.fromJson(Map<String, dynamic> data) {
    final verification = _asMap(data['verification']);
    return CustomerRegistrationResult(
      destination: (verification['destination'] ?? data['destination'] ?? '')
          .toString(),
      developmentOtp: (verification['developmentOtp'] ?? data['developmentOtp'])
          ?.toString(),
      expiresInMinutes: _asInt(
        verification['expiresInMinutes'] ?? data['expiresInMinutes'],
      ),
    );
  }
}

class PasswordResetRequestResult {
  const PasswordResetRequestResult({
    required this.destination,
    this.developmentOtp,
    this.expiresInMinutes,
  });

  final String destination;
  final String? developmentOtp;
  final int? expiresInMinutes;

  factory PasswordResetRequestResult.fromJson(Map<String, dynamic> data) {
    return PasswordResetRequestResult(
      destination: (data['destination'] ?? '').toString(),
      developmentOtp: data['developmentOtp']?.toString(),
      expiresInMinutes: _asInt(data['expiresInMinutes']),
    );
  }
}

class PasswordResetVerificationResult {
  const PasswordResetVerificationResult({
    required this.resetToken,
    this.expiresAt,
    this.expiresInMinutes,
  });

  final String resetToken;
  final String? expiresAt;
  final int? expiresInMinutes;

  factory PasswordResetVerificationResult.fromJson(Map<String, dynamic> data) {
    return PasswordResetVerificationResult(
      resetToken: (data['resetToken'] ?? '').toString(),
      expiresAt: data['expiresAt']?.toString(),
      expiresInMinutes: _asInt(data['expiresInMinutes']),
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

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}
