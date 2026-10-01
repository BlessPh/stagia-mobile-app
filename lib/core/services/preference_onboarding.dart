import 'package:shared_preferences/shared_preferences.dart';

class PreferenceOnboarding {
  const PreferenceOnboarding();

  static const cleTerminee = 'onboarding_termine';

  Future<bool> estTerminee() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(cleTerminee) ?? false;
  }

  Future<void> terminer() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(cleTerminee, true);
  }
}
