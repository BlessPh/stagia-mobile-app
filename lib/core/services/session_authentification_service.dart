import 'package:shared_preferences/shared_preferences.dart';

abstract final class SessionAuthentificationService {
  static const _cleJeton = 'jeton_authentification';
  static const _cleTypeJeton = 'type_jeton_authentification';
  static const _cleStagiaCode = 'stagia_code';
  static const _cleEmail = 'email_etudiant';
  static const _cleMatricule = 'matricule_etudiant';
  static const _cleNom = 'nom_etudiant';
  static const _clePrenom = 'prenom_etudiant';

  static Future<void> enregistrer(Map<String, dynamic> data) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cleJeton, data['token']?.toString() ?? '');
    await preferences.setString(
      _cleTypeJeton,
      data['token_type']?.toString() ?? 'Bearer',
    );

    final user = data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : null;
    final student = data['student'] is Map ? Map<String, dynamic>.from(data['student'] as Map) : null;

    final email = user?['email'] ?? student?['email'] ?? data['email'];
    final stagiaCode = student?['stagia_code'] ?? user?['stagia_code'] ?? data['stagia_code'];
    final matricule = student?['matricule'] ?? stagiaCode ?? user?['matricule'] ?? user?['identifiant'];
    final nom = student?['nom'] ?? user?['nom'] ?? '';
    final prenom = student?['prenom'] ?? user?['prenom'] ?? '';

    await preferences.setString(_cleEmail, email?.toString() ?? '');
    await preferences.setString(_cleMatricule, matricule?.toString() ?? '');
    await preferences.setString(_cleStagiaCode, stagiaCode?.toString() ?? '');
    await preferences.setString(_cleNom, nom.toString());
    await preferences.setString(_clePrenom, prenom.toString());
  }

  static Future<String?> jeton() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_cleJeton);
  }

  static Future<bool> estConnecte() async {
    final t = await jeton();
    return t != null && t.isNotEmpty;
  }

  static Future<String?> email() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_cleEmail);
  }

  static Future<String?> matricule() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_cleMatricule);
  }

  static Future<String?> stagiaCode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_cleStagiaCode);
  }

  static Future<Map<String, String>> identite() async {
    final preferences = await SharedPreferences.getInstance();
    return {
      'nom': preferences.getString(_cleNom) ?? '',
      'prenom': preferences.getString(_clePrenom) ?? '',
    };
  }

  static Future<void> supprimer() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_cleJeton);
    await preferences.remove(_cleTypeJeton);
    await preferences.remove(_cleStagiaCode);
    await preferences.remove(_cleEmail);
    await preferences.remove(_cleMatricule);
    await preferences.remove(_cleNom);
    await preferences.remove(_clePrenom);
  }
}
