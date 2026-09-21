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
        'token':
            '6a4b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b',
        'token_type': 'Bearer',
        'expires_in': 2592000, // 30 jours
        'user': <String, dynamic>{
          'id': 30,
          'nom': 'KALONJI',
          'prenom': 'Alfred',
          'email': estEmail ? idNettoye : 'alfred.kalonji@stagia.cd',
          'role_code': 'STAGIAIRE',
          'role_nom': 'Stagiaire',
        },
        'student': <String, dynamic>{
          'id': 30,
          'stagia_code': estCode ? idNettoye : 'STG-ETU-00000030',
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
      entetes: const {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'CONNEXION_REFUSEE',
        message: reponse['message']?.toString() ?? 'Connexion refusée.',
        details: reponse['data'],
      );
    }
    final data = reponse['data'];
    if (data is! Map<String, dynamic> || data['token'] == null) {
      throw const ErreurApi(
        code: 'JETON_ABSENT',
        message: 'Le serveur n’a pas retourné de jeton de connexion.',
      );
    }
    return data;
  }

  /// Récupère l'utilisateur connecté et son profil étudiant associé (`/me.php`).
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

  /// Demande de réinitialisation de mot de passe.
  Future<void> demanderReinitialisation(String identifiant) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return;
    }

    final reponse = await _client.post(
      EndpointsApi.motDePasseOublie,
      corps: {'identifiant': identifiant},
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

  /// Déconnecte la session courante.
  Future<void> deconnecter() async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      await _client.post(EndpointsApi.deconnexion);
    } catch (_) {
      // Tolérance : si le serveur est indisponible ou si logout.php renvoie une erreur,
      // la déconnexion locale doit tout de même aboutir côté mobile.
    }
  }
}
