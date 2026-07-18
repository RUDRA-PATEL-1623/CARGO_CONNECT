import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/driver_session.dart';
import '../storage/auth_token_storage.dart';

final driverAuthControllerProvider = Provider<DriverAuthController>((ref) {
  final controller = DriverAuthController(
    tokenStorage: ref.watch(authTokenStorageProvider),
  );

  unawaited(controller.ensureInitialized());
  ref.onDispose(controller.dispose);
  return controller;
});

class DriverAuthController extends ChangeNotifier {
  DriverAuthController({required AuthTokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  final AuthTokenStorage _tokenStorage;

  Future<void>? _initialization;
  DriverSession? _session;
  bool _isInitializing = true;

  DriverSession? get session => _session;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated =>
      _session != null && _session!.role == 'driver' && !_session!.isExpired;

  Future<void> ensureInitialized() {
    return _initialization ??= reload();
  }

  Future<void> reload() async {
    _isInitializing = true;
    notifyListeners();

    _session = await _tokenStorage.readSession();
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> markLoggedIn() async {
    _session = await _tokenStorage.readSession();
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> handleUnauthorized() async {
    await _tokenStorage.clear();
    _session = null;
    _isInitializing = false;
    notifyListeners();
  }
}
