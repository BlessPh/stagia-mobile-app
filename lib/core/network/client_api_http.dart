import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/session_authentification_service.dart';
import 'client_api.dart';
import 'configuration_api.dart';
import 'endpoints_api.dart';
import 'reponse_api.dart';

enum ResultatRafraichissementSession {
  reussi,
  indisponible,
  refuse,
  aucunRefreshToken,
}

class ClientApiHttp implements ClientApi {
  ClientApiHttp({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<Map<String, dynamic>> get(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) => _envoyer('GET', chemin, parametres: parametres);

  @override
  Future<Map<String, dynamic>> post(
    String chemin, {
    Object? corps,
    Map<String, String>? entetes,
  }) => _envoyer('POST', chemin, corps: corps, entetes: entetes);

  @override
  Future<Map<String, dynamic>> patch(String chemin, {Object? corps}) =>
      _envoyer('PATCH', chemin, corps: corps);

  @override
  Future<Map<String, dynamic>> delete(String chemin) =>
      _envoyer('DELETE', chemin);

  @override
  Future<Map<String, dynamic>> envoyerFichier(
    String chemin, {
    required String cheminFichier,
    required Map<String, String> champs,
    String cleFichier = 'document',
  }) async {
    final base = Uri.parse(
      ConfigurationApi.urlBase.trim().isNotEmpty
          ? ConfigurationApi.urlBase.trim()
          : 'http://localhost/stagia/api/v1',
    );
    String basePath = base.path;
    while (basePath.endsWith('/')) {
      basePath = basePath.substring(0, basePath.length - 1);
    }
    String endpointPath = chemin.startsWith('/') ? chemin : '/$chemin';
    if (basePath.isNotEmpty && endpointPath.startsWith(basePath)) {
      endpointPath = endpointPath.substring(basePath.length);
    }
    final uri = base.replace(path: '$basePath$endpointPath');

    try {
      Future<http.Response> envoyer() async {
        final requete = http.MultipartRequest('POST', uri);
        requete.headers.addAll({
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        });
        final jeton = await SessionAuthentificationService.jeton();
        if (jeton != null && jeton.isNotEmpty) {
          requete.headers['Authorization'] = 'Bearer $jeton';
        }
        requete.fields.addAll(champs);
        requete.files.add(
          await http.MultipartFile.fromPath(cleFichier, cheminFichier),
        );
        final flux = await _client
            .send(requete)
            .timeout(ConfigurationApi.dureeExpiration);
        return http.Response.fromStream(
          flux,
        ).timeout(ConfigurationApi.dureeExpiration);
      }

      var reponse = await envoyer();
      if (reponse.statusCode == 401) {
        final resultat = await rafraichirSessionSiDisponible();
        if (resultat == ResultatRafraichissementSession.reussi) {
          reponse = await envoyer();
        } else if (resultat == ResultatRafraichissementSession.refuse) {
          await SessionAuthentificationService.supprimer();
        }
      }
      final texte = utf8.decode(reponse.bodyBytes);
      Map<String, dynamic> json = <String, dynamic>{};
      if (texte.isNotEmpty) {
        try {
          final contenuJson = jsonDecode(texte);
          if (contenuJson is Map) {
            json = Map<String, dynamic>.from(contenuJson);
          }
        } catch (_) {}
      }

      if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
        throw ErreurApi(
          code: 'HTTP_${reponse.statusCode}',
          message:
              json['message']?.toString() ??
              'Erreur lors de l\'envoi du fichier (${reponse.statusCode}).',
          details: json['data'],
        );
      }
      return json;
    } on ErreurApi {
      rethrow;
    } on TimeoutException {
      throw const ErreurApi(
        code: 'DELAI_DEPASSE',
        message: 'Le serveur met trop de temps à répondre.',
      );
    } catch (e) {
      throw ErreurApi(
        code: 'ERREUR_UPLOAD',
        message: 'Échec de l\'envoi du document: $e',
      );
    }
  }

  @override
  Future<List<int>> getBytes(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) async {
    final base = Uri.parse(
      ConfigurationApi.urlBase.trim().isNotEmpty
          ? ConfigurationApi.urlBase.trim()
          : 'http://localhost/stagia/api/v1',
    );
    String basePath = base.path;
    while (basePath.endsWith('/')) {
      basePath = basePath.substring(0, basePath.length - 1);
    }
    String endpointPath = chemin.startsWith('/') ? chemin : '/$chemin';
    if (basePath.isNotEmpty && endpointPath.startsWith(basePath)) {
      endpointPath = endpointPath.substring(basePath.length);
    }
    var uri = base.replace(path: '$basePath$endpointPath');
    if (parametres != null && parametres.isNotEmpty) {
      uri = uri.replace(
        queryParameters: parametres.map(
          (cle, valeur) => MapEntry(cle, valeur.toString()),
        ),
      );
    }

    final headers = <String, String>{'ngrok-skip-browser-warning': 'true'};
    final jeton = await SessionAuthentificationService.jeton();
    if (jeton != null && jeton.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jeton';
    }

    var reponse = await _client
        .get(uri, headers: headers)
        .timeout(ConfigurationApi.dureeExpiration);
    if (reponse.statusCode == 401) {
      final resultat = await rafraichirSessionSiDisponible();
      if (resultat == ResultatRafraichissementSession.reussi) {
        final nouveauToken = await SessionAuthentificationService.jeton();
        if (nouveauToken != null && nouveauToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $nouveauToken';
        }
        reponse = await _client
            .get(uri, headers: headers)
            .timeout(ConfigurationApi.dureeExpiration);
      } else if (resultat == ResultatRafraichissementSession.refuse) {
        await SessionAuthentificationService.supprimer();
      }
    }
    if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
      throw ErreurApi(
        code: 'HTTP_${reponse.statusCode}',
        message:
            'Erreur lors du téléchargement du fichier (${reponse.statusCode}).',
      );
    }
    return reponse.bodyBytes;
  }

  Future<Map<String, dynamic>> _envoyer(
    String methode,
    String chemin, {
    Map<String, dynamic>? parametres,
    Object? corps,
    Map<String, String>? entetes,
  }) async {
    final base = Uri.parse(
      ConfigurationApi.urlBase.trim().isNotEmpty
          ? ConfigurationApi.urlBase.trim()
          : 'http://localhost/stagia/api/v1',
    );
    String basePath = base.path;
    while (basePath.endsWith('/')) {
      basePath = basePath.substring(0, basePath.length - 1);
    }
    String endpointPath = chemin.startsWith('/') ? chemin : '/$chemin';
    if (basePath.isNotEmpty && endpointPath.startsWith(basePath)) {
      endpointPath = endpointPath.substring(basePath.length);
    }
    var uri = base.replace(path: '$basePath$endpointPath');
    if (parametres != null && parametres.isNotEmpty) {
      uri = uri.replace(
        queryParameters: parametres.map(
          (cle, valeur) => MapEntry(cle, valeur.toString()),
        ),
      );
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      ...?entetes,
    };
    final estRoutePublique =
        chemin == EndpointsApi.connexion ||
        chemin == EndpointsApi.rafraichirToken ||
        chemin == EndpointsApi.motDePasseOublie ||
        chemin == EndpointsApi.reinitialiserMotDePasse;
    if (!estRoutePublique) {
      final jeton = await SessionAuthentificationService.jeton();
      if (jeton != null && jeton.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jeton';
      }
    }

    try {
      final formulaire =
          headers['Content-Type'] == 'application/x-www-form-urlencoded';
      Object? contenu;
      if (corps != null) {
        if (formulaire && corps is Map) {
          contenu = corps.map(
            (cle, valeur) => MapEntry(cle.toString(), valeur.toString()),
          );
        } else {
          headers['Content-Type'] = 'application/json';
          contenu = jsonEncode(corps);
        }
      }

      final requete = http.Request(methode, uri)..headers.addAll(headers);
      if (contenu is Map<String, String>) {
        requete.bodyFields = contenu;
      } else if (contenu is String) {
        requete.body = contenu;
      }

      final flux = await _client
          .send(requete)
          .timeout(ConfigurationApi.dureeExpiration);
      final reponse = await http.Response.fromStream(
        flux,
      ).timeout(ConfigurationApi.dureeExpiration);
      final texte = utf8.decode(reponse.bodyBytes);
      Map<String, dynamic> json = <String, dynamic>{};
      if (texte.isNotEmpty) {
        try {
          final contenuJson = jsonDecode(texte);
          if (contenuJson is Map) {
            json = Map<String, dynamic>.from(contenuJson);
          }
        } on FormatException {
          if (reponse.statusCode >= 200 && reponse.statusCode < 300) rethrow;
        }
      }

      // Gestion automatique du 401 avec rafraîchissement des tokens
      if (reponse.statusCode == 401 && !estRoutePublique) {
        final resultat = await rafraichirSessionSiDisponible();
        if (resultat == ResultatRafraichissementSession.reussi) {
          // Rejouer la requête une seule fois avec le nouveau token
          final nouveauToken = await SessionAuthentificationService.jeton();
          final nouveauxHeaders = Map<String, String>.from(headers);
          if (nouveauToken != null && nouveauToken.isNotEmpty) {
            nouveauxHeaders['Authorization'] = 'Bearer $nouveauToken';
          }
          final requeteRetry = http.Request(methode, uri)
            ..headers.addAll(nouveauxHeaders);
          if (contenu is Map<String, String>) {
            requeteRetry.bodyFields = contenu;
          } else if (contenu is String) {
            requeteRetry.body = contenu;
          }
          final fluxRetry = await _client
              .send(requeteRetry)
              .timeout(ConfigurationApi.dureeExpiration);
          final reponseRetry = await http.Response.fromStream(
            fluxRetry,
          ).timeout(ConfigurationApi.dureeExpiration);
          final texteRetry = utf8.decode(reponseRetry.bodyBytes);
          Map<String, dynamic> jsonRetry = <String, dynamic>{};
          if (texteRetry.isNotEmpty) {
            try {
              final parsed = jsonDecode(texteRetry);
              if (parsed is Map) jsonRetry = Map<String, dynamic>.from(parsed);
            } catch (_) {}
          }
          if (reponseRetry.statusCode >= 200 && reponseRetry.statusCode < 300) {
            return jsonRetry;
          }
        } else if (resultat == ResultatRafraichissementSession.refuse) {
          // Seul un refus explicite du serveur invalide la session locale.
          // Une coupure réseau ou un serveur indisponible conserve l'état local.
          await SessionAuthentificationService.supprimer();
        }
      }

      if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
        final ngrokHorsLigne =
            texte.contains('ERR_NGROK_3200') ||
            texte.toLowerCase().contains('endpoint is offline');
        throw ErreurApi(
          code: ngrokHorsLigne
              ? 'SERVEUR_NGROK_HORS_LIGNE'
              : 'HTTP_${reponse.statusCode}',
          message: ngrokHorsLigne
              ? 'Le serveur est hors ligne.'
              : json['message']?.toString() ??
                    'Erreur du serveur (${reponse.statusCode}).',
          details: json['data'],
        );
      }
      return json;
    } on ErreurApi {
      rethrow;
    } on TimeoutException {
      throw const ErreurApi(
        code: 'DELAI_DEPASSE',
        message: 'Le serveur met trop de temps à répondre.',
      );
    } on http.ClientException {
      throw const ErreurApi(
        code: 'SERVEUR_INJOIGNABLE',
        message: 'Serveur inaccessible ou requête bloquée par le navigateur.',
      );
    } on FormatException {
      throw const ErreurApi(
        code: 'REPONSE_INVALIDE',
        message: 'La réponse reçue du serveur est invalide.',
      );
    }
  }

  // Verrou global : plusieurs écrans et plusieurs instances HTTP peuvent
  // recevoir un 401 simultanément, mais un seul refresh doit être envoyé.
  static Completer<ResultatRafraichissementSession>? _verrouRafraichissement;

  Future<ResultatRafraichissementSession>
  rafraichirSessionSiDisponible() async {
    if (_verrouRafraichissement != null) {
      return _verrouRafraichissement!.future;
    }

    final completer = Completer<ResultatRafraichissementSession>();
    _verrouRafraichissement = completer;

    try {
      final currentRefresh =
          await SessionAuthentificationService.refreshToken();
      if (currentRefresh == null || currentRefresh.isEmpty) {
        const resultat = ResultatRafraichissementSession.aucunRefreshToken;
        completer.complete(resultat);
        return resultat;
      }

      final base = Uri.parse(
        ConfigurationApi.urlBase.trim().isNotEmpty
            ? ConfigurationApi.urlBase.trim()
            : 'http://localhost/stagia/api/v1',
      );
      String basePath = base.path;
      while (basePath.endsWith('/')) {
        basePath = basePath.substring(0, basePath.length - 1);
      }
      final uri = base.replace(
        path: '$basePath${EndpointsApi.rafraichirToken}',
      );

      final reponse = await _client
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'refresh_token': currentRefresh}),
          )
          .timeout(ConfigurationApi.dureeExpiration);

      if (reponse.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(reponse.bodyBytes),
        );
        if (data['success'] == true && data['data'] is Map) {
          final payload = data['data'] as Map<String, dynamic>;
          final access = payload['access_token']?.toString();
          final refresh = payload['refresh_token']?.toString();
          if (access != null && access.isNotEmpty) {
            await SessionAuthentificationService.mettreAJourJetons(
              accessToken: access,
              refreshToken: refresh,
              expiresIn: _entier(payload['expires_in']),
              refreshExpiresIn: _entier(payload['refresh_expires_in']),
            );
            const resultat = ResultatRafraichissementSession.reussi;
            completer.complete(resultat);
            return resultat;
          }
        }
      }
      final resultat = reponse.statusCode == 401 || reponse.statusCode == 403
          ? ResultatRafraichissementSession.refuse
          : ResultatRafraichissementSession.indisponible;
      completer.complete(resultat);
      return resultat;
    } on TimeoutException {
      const resultat = ResultatRafraichissementSession.indisponible;
      completer.complete(resultat);
      return resultat;
    } on http.ClientException {
      const resultat = ResultatRafraichissementSession.indisponible;
      completer.complete(resultat);
      return resultat;
    } catch (_) {
      const resultat = ResultatRafraichissementSession.indisponible;
      completer.complete(resultat);
      return resultat;
    } finally {
      _verrouRafraichissement = null;
    }
  }

  static int? _entier(dynamic valeur) {
    if (valeur is int) return valeur;
    return int.tryParse(valeur?.toString() ?? '');
  }
}
