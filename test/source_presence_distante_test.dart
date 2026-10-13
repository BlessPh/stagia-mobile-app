import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test('transmet tous les filtres de GET /student/attendance', () async {
    final client = _ClientPresenceEspion();
    final source = SourceEtudiantDistante(client);

    final resultat = await source.presences(
      assignmentUuid: 'assignment-uuid',
      rotationUuid: 'rotation-uuid',
      status: ['PRESENT', 'RETARD'],
      dateFrom: '2026-10-01',
      dateTo: '2026-10-31',
      page: 2,
      perPage: 50,
    );

    expect(client.cheminGet, EndpointsApi.presencesEtudiant);
    expect(client.parametresGet, {
      'assignment_uuid': 'assignment-uuid',
      'rotation_uuid': 'rotation-uuid',
      'status': 'PRESENT,RETARD',
      'date_from': '2026-10-01',
      'date_to': '2026-10-31',
      'page': 2,
      'per_page': 50,
    });
    expect((resultat['items'] as List), isEmpty);
    expect((resultat['stats'] as Map)['total'], 0);
  });

  test('pointe l\'arrivée sans envoyer de corps ni identifiant', () async {
    final client = _ClientPresenceEspion();
    final source = SourceEtudiantDistante(client);

    final resultat = await source.pointerArrivee();

    expect(client.cheminPost, EndpointsApi.pointageArrivee);
    expect(client.corpsPost, isNull);
    expect(resultat['message'], 'Arrivée pointée à 08:02.');
    final punch = resultat['punch'] as Map<String, dynamic>;
    expect(punch['next_action'], 'DEPART');
    expect((punch['attendance'] as Map)['arrival_time'], '08:02:00');
  });

  test('pointe le départ sans envoyer de corps ni identifiant', () async {
    final client = _ClientPresenceEspion();
    final source = SourceEtudiantDistante(client);

    final resultat = await source.pointerDepart();

    expect(client.cheminPost, EndpointsApi.pointageDepart);
    expect(client.corpsPost, isNull);
    expect(resultat['message'], 'Départ pointé à 16:10.');
    final punch = resultat['punch'] as Map<String, dynamic>;
    expect(punch['next_action'], 'TERMINE');
    expect(punch['can_punch'], isFalse);
    expect((punch['attendance'] as Map)['departure_time'], '16:10:00');
  });

  test('charge le contexte canonique pour une affectation donnée', () async {
    final client = _ClientPresenceEspion();
    final source = SourceEtudiantDistante(client);

    final resultat = await source.contexteExecution(
      assignmentUuid: 'assignment-uuid',
    );

    expect(client.cheminGet, EndpointsApi.contexteExecution);
    expect(client.parametresGet, {'assignment_uuid': 'assignment-uuid'});
    final context = resultat['context'] as Map<String, dynamic>;
    expect((context['assignment'] as Map)['uuid'], 'assignment-uuid');
    expect((resultat['execution'] as Map)['can_logbook'], isTrue);
    expect((resultat['punch'] as Map)['next_action'], 'ARRIVEE');
  });
}

class _ClientPresenceEspion implements ClientApi {
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
    if (chemin == EndpointsApi.contexteExecution) {
      return {
        'success': true,
        'message': '',
        'data': {
          'context': {
            'date': '2026-10-09',
            'assignment': {
              'id': 47,
              'uuid': 'assignment-uuid',
              'status': 'ACTIVE',
            },
            'campaign': {'id': 39, 'title': 'Stage clinique 2026'},
            'hospital': {'id': 7, 'name': 'Hôpital Général'},
            'department': {'id': 3, 'name': 'Médecine'},
            'current_rotation': {
              'id': 81,
              'uuid': 'rotation-uuid',
              'status': 'ACTIVE',
              'service': {'id': 8, 'name': 'Pédiatrie'},
            },
            'next_rotation': null,
            'attendance': null,
            'actions': {
              'arrival': {'allowed': true},
              'departure': {'allowed': false},
              'logbook': {'allowed': true},
            },
            'capabilities': {
              'attendance': true,
              'logbook': true,
              'evaluation': true,
            },
            'reason': null,
            'unlock_date': null,
          },
          'execution': <String, dynamic>{},
          'punch': <String, dynamic>{},
        },
      };
    }
    return {
      'success': true,
      'message': '',
      'data': {
        'items': <Map<String, dynamic>>[],
        'stats': {'total': 0},
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
    final estArrivee = chemin == EndpointsApi.pointageArrivee;
    return {
      'success': true,
      'message': estArrivee
          ? 'Arrivée pointée à 08:02.'
          : 'Départ pointé à 16:10.',
      'data': {
        'punch': {
          'date': '2026-10-09',
          'attendance': {
            'uuid': 'attendance-uuid',
            'date_presence': '2026-10-09',
            'heure_arrivee': '08:02:00',
            'heure_depart': estArrivee ? null : '16:10:00',
            'statut': 'PRESENT',
          },
          'can_punch': estArrivee,
          'next_action': estArrivee ? 'DEPART' : 'TERMINE',
          'reason': estArrivee ? null : 'Votre pointage est terminé.',
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
