import 'package:shared_preferences/shared_preferences.dart';

class PreferenceOnboarding {
  const PreferenceOnboarding();

  static const cleTerminee = 'onboarding_termine';
  static const afficherToujoursEnDeveloppement = true;

  Future<bool> estTerminee() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(cleTerminee)) {
      return preferences.getBool(cleTerminee) ?? false;
    }
    if (afficherToujoursEnDeveloppement) return false;
    return false;
  }

  Future<void> terminer() async {
    if (afficherToujoursEnDeveloppement) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(cleTerminee, true);
  }
}
