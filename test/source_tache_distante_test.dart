import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test('transmet tous les filtres de GET /student/tasks', () async {
    final client = _ClientTacheEspion();
    final source = SourceEtudiantDistante(client);

    await source.taches(
      status: ['A_FAIRE', 'EN_COURS'],
      priority: ['HAUTE', 'URGENTE'],
      assignmentUuid: 'assignment-uuid',
      rotationUuid: 'rotation-uuid',
      dueFrom: '2026-10-01',
      dueTo: '2026-10-31',
      page: 2,
      perPage: 50,
    );

    expect(client.cheminGet, EndpointsApi.tachesEtudiant);
    expect(client.parametresGet, {
      'assignment_uuid': 'assignment-uuid',
      'rotation_uuid': 'rotation-uuid',
      'status': 'A_FAIRE,EN_COURS',
      'priority': 'HAUTE,URGENTE',
      'due_from': '2026-10-01',
      'due_to': '2026-10-31',
      'page': 2,
      'per_page': 50,
    });
  });

  test(
    'démarre une tâche sans corps lorsque le commentaire est absent',
    () async {
      final client = _ClientTacheEspion();
      final resultat = await SourceEtudiantDistante(
        client,
      ).demarrerTache('task-uuid');

      expect(client.cheminPost, EndpointsApi.demarrerTache('task-uuid'));
      expect(client.corpsPost, isNull);
      expect((resultat['task'] as Map)['status'], 'EN_COURS');
    },
  );

  test('envoie le commentaire obligatoire à la route comment', () async {
    final client = _ClientTacheEspion();
    await SourceEtudiantDistante(
      client,
    ).commenterTache('task-uuid', '  Travail réalisé.  ');

    expect(client.cheminPost, EndpointsApi.commenterTache('task-uuid'));
    expect(client.corpsPost, {'comment': 'Travail réalisé.'});
  });

  test('termine une tâche avec un commentaire optionnel', () async {
    final client = _ClientTacheEspion();
    final resultat = await SourceEtudiantDistante(
      client,
    ).terminerTache('task-uuid', commentaire: 'Terminée sous supervision.');

    expect(client.cheminPost, EndpointsApi.terminerTache('task-uuid'));
    expect(client.corpsPost, {'comment': 'Terminée sous supervision.'});
    expect((resultat['task'] as Map)['status'], 'TERMINEE');
  });
}

class _ClientTacheEspion implements ClientApi {
  String? cheminGet;
  Map<String, dynamic>? parametresGet;
  String? cheminPost;
  Object? corpsPost;

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
        'items': <Map<String, dynamic>>[],
        'stats': {'total': 0},
        'progress': 0,
        'pagination': {'page': 2, 'per_page': 50, 'total': 0, 'pages': 0},
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String chemin, {
    Object? corps,
    Map<String, String>? entetes,
  }) async {
    cheminPost = chemin;
    corpsPost = corps;
    final status = chemin.endsWith('/complete') ? 'TERMINEE' : 'EN_COURS';
    return {
      'success': true,
      'message': status == 'TERMINEE' ? 'Tache terminee.' : 'Tache demarree.',
      'data': {
        'task': {
          'uuid': 'task-uuid',
          'title': 'Consultation',
          'status': status,
          'actions': {
            'start': {'allowed': false},
            'comment': {'allowed': true},
            'complete': {'allowed': status == 'EN_COURS'},
          },
        },
      },
    };
  }

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
