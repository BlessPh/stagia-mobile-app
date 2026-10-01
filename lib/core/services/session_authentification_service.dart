import 'package:shared_preferences/shared_preferences.dart';

abstract final class SessionAuthentificationService {
  static const _cleJeton = 'jeton_authentification';
  static const _cleRefreshToken = 'refresh_token_authentification';
  static const _cleTypeJeton = 'type_jeton_authentification';
  static const _cleStagiaCode = 'stagia_code';
  static const _cleEmail = 'email_etudiant';
  static const _cleMatricule = 'matricule_etudiant';
  static const _cleNom = 'nom_etudiant';
  static const _clePrenom = 'prenom_etudiant';
  static const _cleSessionLocale = 'session_authentifiee_locale';
  static const _cleExpirationJeton = 'expiration_jeton_authentification';
  static const _cleExpirationRefresh = 'expiration_refresh_authentification';

  static Future<void> enregistrer(Map<String, dynamic> data) async {
    final preferences = await SharedPreferences.getInstance();

    // Supporte access_token (nouveau contrat OpenAPI v1) et token (rétrocompatibilité)
    final token =
        data['access_token']?.toString() ?? data['token']?.toString() ?? '';
    final refreshToken = data['refresh_token']?.toString() ?? '';

    if (token.isNotEmpty) {
      await preferences.setString(_cleJeton, token);
    }
    if (refreshToken.isNotEmpty) {
      await preferences.setString(_cleRefreshToken, refreshToken);
    } else {
      await preferences.remove(_cleRefreshToken);
    }
    await preferences.setString(
      _cleTypeJeton,
      data['token_type']?.toString() ?? 'Bearer',
    );

    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : null;
    final student = data['student'] is Map
        ? Map<String, dynamic>.from(data['student'] as Map)
        : null;

    final email = user?['email'] ?? student?['email'] ?? data['email'];
    final stagiaCode =
        student?['stagia_code'] ?? user?['stagia_code'] ?? data['stagia_code'];
    final matricule =
        student?['matricule'] ??
        stagiaCode ??
        user?['matricule'] ??
        user?['identifiant'];
    final nom = student?['nom'] ?? user?['nom'] ?? '';
    final prenom = student?['prenom'] ?? user?['prenom'] ?? '';

    await preferences.setString(_cleEmail, email?.toString() ?? '');
    await preferences.setString(_cleMatricule, matricule?.toString() ?? '');
    await preferences.setString(_cleStagiaCode, stagiaCode?.toString() ?? '');
    await preferences.setString(_cleNom, nom.toString());
    await preferences.setString(_clePrenom, prenom.toString());
    await preferences.setBool(_cleSessionLocale, true);
    await _enregistrerExpirations(
      preferences,
      expiresIn: _entier(data['expires_in']),
      refreshExpiresIn: _entier(data['refresh_expires_in']),
    );
  }

  /// Met à jour uniquement la paire de jetons après un renouvellement (/refresh-token)
  static Future<void> mettreAJourJetons({
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
    int? refreshExpiresIn,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cleJeton, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await preferences.setString(_cleRefreshToken, refreshToken);
    }
    await preferences.setBool(_cleSessionLocale, true);
    await _enregistrerExpirations(
      preferences,
      expiresIn: expiresIn,
      refreshExpiresIn: refreshExpiresIn,
    );
  }

  static Future<String?> jeton() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_cleJeton);
  }

  static Future<String?> refreshToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_cleRefreshToken);
  }

  static Future<bool> estConnecte() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_cleSessionLocale) == true) return true;

    // Migration transparente des sessions créées avant l'ajout du marqueur
    // local : un access token ou un refresh token suffit à restaurer l'état.
    final access = preferences.getString(_cleJeton) ?? '';
    final refresh = preferences.getString(_cleRefreshToken) ?? '';
    final existe = access.isNotEmpty || refresh.isNotEmpty;
    if (existe) await preferences.setBool(_cleSessionLocale, true);
    return existe;
  }

  static Future<bool> aUnRefreshToken() async {
    final token = await refreshToken();
    return token != null && token.isNotEmpty;
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
    await preferences.remove(_cleRefreshToken);
    await preferences.remove(_cleTypeJeton);
    await preferences.remove(_cleStagiaCode);
    await preferences.remove(_cleEmail);
    await preferences.remove(_cleMatricule);
    await preferences.remove(_cleNom);
    await preferences.remove(_clePrenom);
    await preferences.remove(_cleSessionLocale);
    await preferences.remove(_cleExpirationJeton);
    await preferences.remove(_cleExpirationRefresh);
  }

  static int? _entier(dynamic valeur) {
    if (valeur is int) return valeur;
    return int.tryParse(valeur?.toString() ?? '');
  }

  static Future<void> _enregistrerExpirations(
    SharedPreferences preferences, {
    int? expiresIn,
    int? refreshExpiresIn,
  }) async {
    final maintenant = DateTime.now();
    if (expiresIn != null && expiresIn > 0) {
      await preferences.setString(
        _cleExpirationJeton,
        maintenant.add(Duration(seconds: expiresIn)).toUtc().toIso8601String(),
      );
    }
    if (refreshExpiresIn != null && refreshExpiresIn > 0) {
      await preferences.setString(
        _cleExpirationRefresh,
        maintenant
            .add(Duration(seconds: refreshExpiresIn))
            .toUtc()
            .toIso8601String(),
      );
    }
  }
}
