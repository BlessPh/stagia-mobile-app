import '../../../../core/mocks/donnees_etudiant_mockees.dart';
import '../../../../core/network/client_api.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/endpoints_api.dart';
import '../../../../core/network/reponse_api.dart';

class SourceAuthentificationDistante {
  const SourceAuthentificationDistante(this._client);
  final ClientApi _client;

  /// Connecte un utilisateur via son identifiant (e-mail, identifiant ou code STAGIA)
  /// et son mot de passe.
  ///
  /// En mode mock (`ConfigurationApi.utiliserDonneesMockees == true`),
  /// renvoie la charge utile exacte `LoginResponse` du contrat OpenAPI PHP.
  /// En mode API réelle, appelle l'endpoint PHP `/auth/login.php`.
  Future<Map<String, dynamic>> connecter({
    required String identifiant,
    required String motDePasse,
    String nomAppareil = 'Stagia Mobile',
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      // Simulation réaliste de latence réseau
      await Future<void>.delayed(const Duration(milliseconds: 700));

      final idNettoye = identifiant.trim();
      final passNettoye = motDePasse.trim();

      if (idNettoye.isEmpty || passNettoye.isEmpty) {
        throw const ErreurApi(
          code: 'IDENTIFIANTS_REQUIS',
          message: 'L’identifiant et le mot de passe sont obligatoires.',
        );
      }

      // Mot de passe déclencheur de simulation d'erreur pour tester l'échec
      if (passNettoye == 'erreur' || passNettoye == 'fail') {
        throw const ErreurApi(
          code: 'CONNEXION_REFUSEE',
          message: 'Identifiant ou mot de passe incorrect.',
        );
      }

      // Données mockées strictement conformes au schéma LoginResponse
      final estEmail = idNettoye.contains('@');
      final estCode = idNettoye.toUpperCase().startsWith('STG-');

      return <String, dynamic>{
        'access_token':
            '6a4b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b',
        'refresh_token':
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'refresh_expires_in': 2592000,
        'user': <String, dynamic>{
          'id': 30,
          'identifiant': 'etu.kalonji',
          'nom': 'KALONJI',
          'postnom': 'MUKENDI',
          'prenom': 'Alfred',
          'email': estEmail ? idNettoye : 'alfred.kalonji@stagia.cd',
          'actif': true,
          'statut_compte': 'ACTIF',
          'role': {'code': 'STAGIAIRE', 'nom': 'Stagiaire'},
          'roles': ['STAGIAIRE'],
        },
        'student': <String, dynamic>{
          'id': 30,
          'stagia_code': estCode ? idNettoye : 'STG-ETU-00000030',
          'nom': 'KALONJI',
          'postnom': 'MUKENDI',
          'prenom': 'Alfred',
          'statut': 'ACTIF',
        },
      };
    }

    final reponse = await _client.post(
      EndpointsApi.connexion,
      corps: {
        'identifiant': identifiant,
        'password': motDePasse,
        'device_name': nomAppareil,
      },
      entetes: const {'Content-Type': 'application/json'},
    );

    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'CONNEXION_REFUSEE',
        message: reponse['message']?.toString() ?? 'Connexion refusée.',
        details: reponse['data'],
      );
    }
    final data = reponse['data'];
    if (data is! Map<String, dynamic> ||
        (data['access_token'] == null && data['token'] == null)) {
      throw const ErreurApi(
        code: 'JETON_ABSENT',
        message: 'Le serveur n’a pas retourné de jeton de connexion.',
      );
    }
    return data;
  }

  /// Renouvelle l'access_token et le refresh_token (/refresh-token).
  Future<Map<String, dynamic>> rafraichirToken(String refreshToken) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return {
        'access_token':
            'new_access_token_6a4b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f',
        'refresh_token':
            'new_refresh_token_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'refresh_expires_in': 2592000,
      };
    }

    final reponse = await _client.post(
      EndpointsApi.rafraichirToken,
      corps: {'refresh_token': refreshToken},
      entetes: const {'Content-Type': 'application/json'},
    );

    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REFRESH_REFUSE',
        message: reponse['message']?.toString() ?? 'Session expirée.',
        details: reponse['data'],
      );
    }

    final data = reponse['data'];
    if (data is! Map<String, dynamic>) {
      throw const ErreurApi(
        code: 'DONNEES_INVALIDES',
        message: 'Données de renouvellement de session invalides.',
      );
    }
    return data;
  }

  /// Récupère l'utilisateur connecté et son profil étudiant associé (`/me`).
  Future<Map<String, dynamic>> me() async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return DonneesEtudiantMockees.profil;
    }

    final reponse = await _client.get(EndpointsApi.profilEtudiant);
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'PROFIL_REFUSE',
        message: reponse['message']?.toString() ?? 'Impossible de récupérer le profil.',
        details: reponse['data'],
      );
    }
    final data = reponse['data'];
    if (data is! Map<String, dynamic>) {
      throw const ErreurApi(
        code: 'DONNEES_INVALIDES',
        message: 'Les informations du profil reçues sont invalides.',
      );
    }
    return data;
  }

  /// Demande de réinitialisation de mot de passe (`/forgot-password`).
  Future<void> demanderReinitialisation(String identifiant) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return;
    }

    final isEmail = identifiant.contains('@');
    final corps = isEmail
        ? {'email': identifiant.trim()}
        : {'identifiant': identifiant.trim()};

    final reponse = await _client.post(
      EndpointsApi.motDePasseOublie,
      corps: corps,
      entetes: const {'Content-Type': 'application/json'},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'RECUPERATION_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'La demande de réinitialisation a été refusée.',
        details: reponse['data'],
      );
    }
  }

  /// Réinitialise le mot de passe via le token reçu (`/reset-password`).
  Future<void> reinitialiserMotDePasse({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return;
    }

    final reponse = await _client.post(
      EndpointsApi.reinitialiserMotDePasse,
      corps: {
        'token': token.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      entetes: const {'Content-Type': 'application/json'},
    );

    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REINITIALISATION_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible de réinitialiser le mot de passe.',
        details: reponse['data'],
      );
    }
  }

  /// Déconnecte la session courante (`/logout`).
  Future<void> deconnecter() async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      await _client.post(EndpointsApi.deconnexion);
    } catch (_) {
      // Tolérance : si le serveur est indisponible ou répond avec une erreur,
      // la déconnexion locale doit tout de même aboutir côté mobile.
    }
  }
}
