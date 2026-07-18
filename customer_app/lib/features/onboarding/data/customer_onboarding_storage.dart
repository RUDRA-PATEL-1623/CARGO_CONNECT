import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final customerOnboardingStorageProvider = Provider<CustomerOnboardingStorage>((
  ref,
) {
  return CustomerOnboardingStorage();
});

class CustomerOnboardingStorage {
  static const String completedKey = 'customer_onboarding_completed';

  Future<bool> isCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(completedKey) ?? false;
  }

  Future<void> markCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(completedKey, true);
  }
}
