import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_event_notifier.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/auth_token_storage.dart';
import 'admin_auth_api.dart';
import 'admin_session.dart';

final adminAuthControllerProvider = Provider<AdminAuthController>((ref) {
  final controller = AdminAuthController(
    authApi: ref.watch(adminAuthApiProvider),
    authEvents: ref.watch(authEventNotifierProvider),
    tokenStorage: ref.watch(authTokenStorageProvider),
  );

  unawaited(controller.ensureInitialized());
  ref.onDispose(controller.dispose);
  return controller;
});

class AdminAuthController extends ChangeNotifier {
  AdminAuthController({
    required AdminAuthApi authApi,
    required AuthEventNotifier authEvents,
    required AuthTokenStorage tokenStorage,
  }) : _authApi = authApi,
       _authEvents = authEvents,
       _tokenStorage = tokenStorage {
    _seenUnauthorizedVersion = _authEvents.unauthorizedVersion;
    _authEvents.addListener(_handleAuthEvent);
  }

  final AdminAuthApi _authApi;
  final AuthEventNotifier _authEvents;
  final AuthTokenStorage _tokenStorage;

  Future<void>? _initialization;
  AdminSession? _session;
  bool _isInitializing = true;
  int _seenUnauthorizedVersion = 0;

  AdminSession? get session => _session;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated =>
      _session != null &&
      _session!.isAuthorizedAdminRole &&
      !_session!.isExpired;

  Future<void> ensureInitialized() {
    return _initialization ??= _hydrateSession();
  }

  Future<void> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    final session = await _authApi.login(
      identifier: identifier,
      password: password,
      rememberMe: rememberMe,
    );
    _session = session;
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _authApi.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await logout();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authApi.logout();
    _session = null;
    _isInitializing = false;
    notifyListeners();
  }

  void _handleAuthEvent() {
    if (_authEvents.unauthorizedVersion == _seenUnauthorizedVersion) {
      return;
    }

    _seenUnauthorizedVersion = _authEvents.unauthorizedVersion;
    _session = null;
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> _hydrateSession() async {
    _isInitializing = true;
    notifyListeners();

    _session = await _tokenStorage.readSession();
    _isInitializing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authEvents.removeListener(_handleAuthEvent);
    super.dispose();
  }
}
