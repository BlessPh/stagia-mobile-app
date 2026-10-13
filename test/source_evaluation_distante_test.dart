import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test('transmet tous les filtres de GET /student/evaluations', () async {
    final client = _ClientEvaluationEspion();
    final source = SourceEtudiantDistante(client);

    final resultat = await source.evaluations(
      type: ['CONTINUE', 'FIN_ROTATION'],
      status: ['VALIDEE', 'FINALISEE'],
      assignmentUuid: 'assignment-uuid',
      rotationUuid: 'rotation-uuid',
      dateFrom: '2026-10-01',
      dateTo: '2026-10-31',
      page: 2,
      perPage: 50,
    );

    expect(client.cheminGet, EndpointsApi.evaluationsEtudiant);
    expect(client.parametresGet, {
      'type': 'CONTINUE,FIN_ROTATION',
      'status': 'VALIDEE,FINALISEE',
      'assignment_uuid': 'assignment-uuid',
      'rotation_uuid': 'rotation-uuid',
      'date_from': '2026-10-01',
      'date_to': '2026-10-31',
      'page': 2,
      'per_page': 50,
    });
    final evaluation = (resultat['items'] as List<Map<String, dynamic>>).single;
    expect(evaluation['evaluator_name'], 'Docteur Encadreur');
    expect((resultat['stats'] as Map)['average'], 16.5);
  });
}

class _ClientEvaluationEspion implements ClientApi {
  String? cheminGet;
  Map<String, dynamic>? parametresGet;

  @override
  Future<Map<String, dynamic>> get(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) async {
    cheminGet = chemin;
    parametresGet = parametres;
    return {
      'success': true,
      'message': '',
      'data': {
        'items': [
          {
            'uuid': 'evaluation-uuid',
            'type': 'FIN_ROTATION',
            'status': 'FINALISEE',
            'note': 16.5,
            'score_summary': {'total': 33, 'maximum': 40, 'percentage': 82.5},
            'scores': <Map<String, dynamic>>[],
            'evaluator': {
              'user_id': 14,
              'name': 'Docteur Encadreur',
              'function': 'Maître de stage',
            },
            'assignment': {'uuid': 'assignment-uuid'},
            'rotation': {'uuid': 'rotation-uuid'},
            'campaign': {'title': 'Stage clinique 2026'},
            'hospital': {'name': 'Hôpital Général'},
            'unit': {'name': 'Consultation'},
          },
        ],
        'stats': {'total': 1, 'average': 16.5},
        'final_evaluation': {
          'uuid': 'evaluation-uuid',
          'type': 'FIN_ROTATION',
          'status': 'FINALISEE',
          'note': 16.5,
        },
        'pagination': {'page': 2, 'per_page': 50, 'total': 1, 'pages': 1},
        'filters': <String, dynamic>{},
        'available_filters': <String, dynamic>{},
      },
    };
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
