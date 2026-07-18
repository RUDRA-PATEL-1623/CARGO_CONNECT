import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_session.dart';
import '../storage/auth_token_storage.dart';

final customerAuthControllerProvider = Provider<CustomerAuthController>((ref) {
  final controller = CustomerAuthController(
    tokenStorage: ref.watch(authTokenStorageProvider),
  );

  unawaited(controller.ensureInitialized());
  ref.onDispose(controller.dispose);
  return controller;
});

class CustomerAuthController extends ChangeNotifier {
  CustomerAuthController({required AuthTokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  final AuthTokenStorage _tokenStorage;

  Future<void>? _initialization;
  AuthSession? _session;
  bool _isInitializing = true;

  AuthSession? get session => _session;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated =>
      _session != null && _session!.role == 'customer' && !_session!.isExpired;

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
