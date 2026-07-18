import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/driver_auth_controller.dart';
import '../config/app_config.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final authController = ref.watch(driverAuthControllerProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        await authController.ensureInitialized();
        final session = authController.session;
        if (session != null &&
            session.role == 'driver' &&
            !session.isExpired &&
            session.token.isNotEmpty) {
          options.headers['Authorization'] =
              '${session.tokenType} ${session.token}';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await authController.handleUnauthorized();
          handler.next(error);
          return;
        }

        if (_shouldRetry(error)) {
          final requestOptions = error.requestOptions;
          requestOptions.extra[_retryAttemptKey] =
              _retryAttempt(requestOptions) + 1;

          try {
            final response = await dio.fetch<Object?>(requestOptions);
            handler.resolve(response);
            return;
          } on DioException catch (retryError) {
            handler.next(retryError);
            return;
          }
        }

        handler.next(error);
      },
    ),
  );

  return dio;
});

const String _retryAttemptKey = 'cargoconnect_retry_attempt';
const Set<String> _retryableMethods = {'GET', 'HEAD'};

int _retryAttempt(RequestOptions options) {
  final value = options.extra[_retryAttemptKey];
  return value is int ? value : 0;
}

bool _shouldRetry(DioException error) {
  if (_retryAttempt(error.requestOptions) >= 1) {
    return false;
  }

  if (!_retryableMethods.contains(error.requestOptions.method.toUpperCase())) {
    return false;
  }

  return switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout =>
      true,
    _ => false,
  };
}
