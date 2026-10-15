import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/reponse_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test(
    'envoie le mot de passe et la confirmation au nouvel endpoint',
    () async {
      final client = _ClientDesactivation({
        'success': true,
        'message': 'Compte désactivé.',
        'data': {
          'deletion_request': {
            'uuid': 'deletion-request-1',
            'status': 'PENDING',
            'grace_period_days': 30,
          },
        },
      });

      final resultat = await SourceEtudiantDistante(client).desactiverCompte(
        password: 'mot-de-passe-actuel',
        confirmation: 'DESACTIVER',
      );

      expect(client.chemin, EndpointsApi.desactiverCompteEtudiant);
      expect(client.corps, {
        'password': 'mot-de-passe-actuel',
        'confirmation': 'DESACTIVER',
      });
      expect((resultat['deletion_request'] as Map)['grace_period_days'], 30);
    },
  );

  test('refuse localement une phrase de confirmation incorrecte', () async {
    final client = _ClientDesactivation(const {});

    expect(
      () => SourceEtudiantDistante(
        client,
      ).desactiverCompte(password: 'secret', confirmation: 'SUPPRIMER'),
      throwsA(
        isA<ErreurApi>().having(
          (erreur) => erreur.code,
          'code',
          'CONFIRMATION_DESACTIVATION_INVALIDE',
        ),
      ),
    );
    expect(client.chemin, isNull);
  });

  test('conserve le message d’erreur retourné par le serveur', () async {
    final client = _ClientDesactivation({
      'success': false,
      'message': 'Mot de passe incorrect.',
      'data': null,
    });

    expect(
      () => SourceEtudiantDistante(
        client,
      ).desactiverCompte(password: 'incorrect', confirmation: 'DESACTIVER'),
      throwsA(
        isA<ErreurApi>().having(
          (erreur) => erreur.message,
          'message',
          'Mot de passe incorrect.',
        ),
      ),
    );
  });
}

class _ClientDesactivation implements ClientApi {
  _ClientDesactivation(this.reponse);

  final Map<String, dynamic> reponse;
  String? chemin;
  Object? corps;

  @override
  Future<Map<String, dynamic>> post(
    String chemin, {
    Object? corps,
    Map<String, String>? entetes,
  }) async {
    this.chemin = chemin;
    this.corps = corps;
    return reponse;
  }

  @override
  Future<Map<String, dynamic>> get(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> patch(String chemin, {Object? corps}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> delete(String chemin) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> envoyerFichier(
    String chemin, {
    required String cheminFichier,
    required Map<String, String> champs,
    String cleFichier = 'document',
  }) => throw UnimplementedError();

  @override
  Future<List<int>> getBytes(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) => throw UnimplementedError();
}
