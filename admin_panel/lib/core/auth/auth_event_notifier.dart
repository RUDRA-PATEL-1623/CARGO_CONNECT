import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authEventNotifierProvider = Provider<AuthEventNotifier>((ref) {
  final notifier = AuthEventNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

class AuthEventNotifier extends ChangeNotifier {
  int _unauthorizedVersion = 0;

  int get unauthorizedVersion => _unauthorizedVersion;

  void notifyUnauthorized() {
    _unauthorizedVersion += 1;
    notifyListeners();
  }
}
