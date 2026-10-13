import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test('transmet tous les filtres de GET /student/logbook', () async {
    final client = _ClientJournalEspion();
    final source = SourceEtudiantDistante(client);

    await source.journal(
      status: ['BROUILLON', 'REJETEE'],
      assignmentUuid: 'assignment-uuid',
      rotationUuid: 'rotation-uuid',
      dateFrom: '2026-10-01',
      dateTo: '2026-10-31',
      editable: true,
      page: 2,
      perPage: 50,
    );

    expect(client.cheminGet, EndpointsApi.journalEtudiant);
    expect(client.parametresGet, {
      'assignment_uuid': 'assignment-uuid',
      'rotation_uuid': 'rotation-uuid',
      'status': 'BROUILLON,REJETEE',
      'date_from': '2026-10-01',
      'date_to': '2026-10-31',
      'editable': true,
      'page': 2,
      'per_page': 50,
    });
  });

  test('enregistre le payload et lit data.entry', () async {
    final client = _ClientJournalEspion();
    final resultat = await SourceEtudiantDistante(client).sauvegarderJournal(
      assignmentUuid: 'assignment-uuid',
      date: '2026-10-09',
      summary: 'Consultations pédiatriques.',
      learning: 'Signes de gravité.',
      difficulties: 'Communication.',
      logbookUuid: 'logbook-uuid',
      activities: [
        {
          'category': 'PARTICIPATION',
          'activity': 'Anamnèse',
          'description': 'Interrogatoire supervisé.',
          'involvement_level': 'REALISE_SUPERVISE',
          'quantity': 3,
        },
      ],
    );

    expect(client.cheminPost, EndpointsApi.journalEtudiant);
    expect(client.corpsPost, {
      'assignment_uuid': 'assignment-uuid',
      'date': '2026-10-09',
      'summary': 'Consultations pédiatriques.',
      'learning': 'Signes de gravité.',
      'difficulties': 'Communication.',
      'uuid': 'logbook-uuid',
      'activities': [
        {
          'category': 'PARTICIPATION',
          'activity': 'Anamnèse',
          'description': 'Interrogatoire supervisé.',
          'involvement_level': 'REALISE_SUPERVISE',
          'quantity': 3,
        },
      ],
    });
    expect((resultat['entry'] as Map)['uuid'], 'logbook-uuid');
    expect(resultat['message'], 'Journal enregistré en brouillon.');
  });

  test('soumet sans corps et retourne l’entrée complète actualisée', () async {
    final client = _ClientJournalEspion();
    client.soumission = true;
    final resultat = await SourceEtudiantDistante(
      client,
    ).soumettreJournal(logbookUuid: 'logbook-uuid');

    expect(client.cheminPost, EndpointsApi.soumettreJournal('logbook-uuid'));
    expect(client.corpsPost, isNull);
    final entree = resultat['entry'] as Map<String, dynamic>;
    expect(entree['status'], 'SOUMISE');
    expect(entree['editable'], isFalse);
    expect(entree['can_submit'], isFalse);
  });
}

class _ClientJournalEspion implements ClientApi {
  String? cheminGet;
  Map<String, dynamic>? parametresGet;
  String? cheminPost;
  Object? corpsPost;
  bool soumission = false;

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
        'pagination': {'page': 2, 'per_page': 50, 'total': 0, 'pages': 0},
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
  }) async {
    cheminPost = chemin;
    corpsPost = corps;
    final status = soumission ? 'SOUMISE' : 'BROUILLON';
    return {
      'success': true,
      'message': soumission
          ? 'Journal soumis pour validation.'
          : 'Journal enregistré en brouillon.',
      'data': {
        'entry': {
          'uuid': 'logbook-uuid',
          'date': '2026-10-09',
          'status': status,
          'summary': 'Consultations pédiatriques.',
          'learning': 'Signes de gravité.',
          'activities': <Map<String, dynamic>>[],
          'editable': !soumission,
          'can_submit': !soumission,
          'actions': {
            'edit': {'allowed': !soumission},
            'submit': {'allowed': !soumission},
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
