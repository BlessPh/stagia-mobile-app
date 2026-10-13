import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test('transmet tous les filtres de GET /student/feedbacks', () async {
    final client = _ClientFeedbackEspion();
    final source = SourceEtudiantDistante(client);

    await source.feedbacks(
      type: ['ENCOURAGEMENT', 'A_AMELIORER'],
      assignmentUuid: 'assignment-uuid',
      rotationUuid: 'rotation-uuid',
      seen: false,
      dateFrom: '2026-10-01',
      dateTo: '2026-10-31',
      page: 2,
      perPage: 50,
    );

    expect(client.cheminGet, EndpointsApi.feedbacksEtudiant);
    expect(client.parametresGet, {
      'type': 'ENCOURAGEMENT,A_AMELIORER',
      'assignment_uuid': 'assignment-uuid',
      'rotation_uuid': 'rotation-uuid',
      'seen': false,
      'date_from': '2026-10-01',
      'date_to': '2026-10-31',
      'page': 2,
      'per_page': 50,
    });
  });

  test('marque un seul feedback comme lu sans envoyer de corps', () async {
    final client = _ClientFeedbackEspion();
    final resultat = await SourceEtudiantDistante(
      client,
    ).marquerFeedbackLu('feedback-uuid');

    expect(client.cheminPost, EndpointsApi.lireFeedback('feedback-uuid'));
    expect(client.corpsPost, isNull);
    final feedback = resultat['feedback'] as Map<String, dynamic>;
    expect(feedback['seen'], isTrue);
    expect((feedback['actions'] as Map)['read']['allowed'], isFalse);
  });
}

class _ClientFeedbackEspion implements ClientApi {
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
    return {
      'success': true,
      'message': 'Feedback marque comme lu.',
      'data': {
        'feedback': {
          'uuid': 'feedback-uuid',
          'date': '2026-10-09',
          'type': 'ENCOURAGEMENT',
          'title': 'Bonne progression',
          'comment': 'Bonne qualité d’écoute.',
          'seen': true,
          'seen_at': '2026-10-09 17:05:00',
          'actions': {
            'read': {'allowed': false},
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
