import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';
import 'package:stagia/features/stage/data/mappers/mappeur_visibilite_resultat_stage_api.dart';

void main() {
  test('masque note et certificat avant validation de la clôture', () {
    final resultat = MappeurVisibiliteResultatStageApi.normaliserTableauDeBord({
      'current_stage': {
        'completion_status': 'EN_COURS',
        'note_finale': 17,
        'certificate_uuid': 'certificate-1',
        'certificate_available': true,
        'completion': {'status': 'PRET', 'final_score': 17},
        'certificate': {
          'available': true,
          'uuid': 'certificate-1',
          'file_endpoint': '/student/certificates/certificate-1/file',
        },
      },
    });

    final stage = Map<String, dynamic>.from(resultat['current_stage'] as Map);
    expect(stage['note_finale'], isNull);
    expect(stage['certificate_uuid'], isNull);
    expect(stage['certificate_available'], isFalse);
    expect((stage['completion'] as Map)['final_score'], isNull);
    expect((stage['certificate'] as Map)['available'], isFalse);
    expect((stage['certificate'] as Map)['file_endpoint'], isNull);
  });

  test('conserve le résultat d’une clôture validée', () {
    final resultat = MappeurVisibiliteResultatStageApi.normaliserElement({
      'completion_status': 'VALIDE',
      'note_finale': 18,
      'certificate_available': true,
      'certificate_uuid': 'certificate-2',
    });

    expect(resultat['note_finale'], 18);
    expect(resultat['certificate_available'], isTrue);
    expect(resultat['certificate_uuid'], 'certificate-2');
  });

  test('transmet tous les filtres du contrat des candidatures', () async {
    final client = _ClientApplicationsEspion();
    final source = SourceEtudiantDistante(client);

    final resultat = await source.candidatures(
      status: ['SOUMISE', 'ACCEPTEE'],
      reservationStatus: ['EN_ATTENTE_PAIEMENT', 'CONFIRMEE'],
      workflowStatus: ['EN_ATTENTE_PAIEMENT'],
      campaignId: 39,
      hospitalId: 24,
      page: 2,
      perPage: 50,
    );

    expect(client.cheminGet, EndpointsApi.candidaturesEtudiant);
    expect(client.parametresGet, {
      'status': 'SOUMISE,ACCEPTEE',
      'reservation_status': 'EN_ATTENTE_PAIEMENT,CONFIRMEE',
      'workflow_status': 'EN_ATTENTE_PAIEMENT',
      'campaign_id': 39,
      'hospital_id': 24,
      'page': 2,
      'per_page': 50,
    });
    final candidature = Map<String, dynamic>.from(
      (resultat['items'] as List).single as Map,
    );
    expect(candidature['note_finale'], isNull);
    expect(resultat['pagination'], isA<Map>());
    expect(resultat['available_filters'], isA<Map>());
  });

  test('adapte le suivi des admissions au contrat imbriqué', () async {
    final client = _ClientApplicationsEspion(
      donneesGet: {
        'items': [
          {
            'reservation': {'uuid': 'reservation-1', 'status': 'CONFIRMEE'},
            'application': {'uuid': 'application-1', 'status': 'ACCEPTEE'},
            'placement': {'exists': true, 'status': 'CONFIRME'},
            'admission': {'exists': true, 'status': 'ADMIS'},
            'assignment': {'exists': true, 'status': 'TERMINEE'},
            'completion': {'status': 'PRET', 'final_score': 17},
            'workflow_status': 'STAGE_TERMINE',
          },
        ],
        'stats': {'total': 1, 'completed': 1},
      },
    );

    final resultat = await SourceEtudiantDistante(
      client,
    ).admissions('reservation-1');
    final item = Map<String, dynamic>.from(
      (resultat['items'] as List).single as Map,
    );

    expect(client.cheminGet, EndpointsApi.admissionEtudiant);
    expect(client.parametresGet, {'reservation_uuid': 'reservation-1'});
    expect((resultat['stats'] as Map)['completed'], 1);
    expect((item['completion'] as Map)['final_score'], isNull);
  });
}

class _ClientApplicationsEspion implements ClientApi {
  _ClientApplicationsEspion({Map<String, dynamic>? donneesGet})
    : donneesGet =
          donneesGet ??
          {
            'items': [
              {
                'uuid': 'application-1',
                'completion_status': 'PRET',
                'note_finale': 16,
              },
            ],
            'pagination': {'page': 2, 'per_page': 50, 'total': 1, 'pages': 1},
            'filters': <String, dynamic>{},
            'available_filters': <String, dynamic>{},
          };

  final Map<String, dynamic> donneesGet;
  String? cheminGet;
  Map<String, dynamic>? parametresGet;

  @override
  Future<Map<String, dynamic>> get(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) async {
    cheminGet = chemin;
    parametresGet = parametres;
    return {'success': true, 'message': '', 'data': donneesGet};
  }

  @override
  Future<Map<String, dynamic>> post(
    String chemin, {
    Object? corps,
    Map<String, String>? entetes,
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
